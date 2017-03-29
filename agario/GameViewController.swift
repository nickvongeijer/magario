//
//  GameViewController.swift
//  agar-clone
//
//  Created by Ming on 8/24/15.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

import UIKit
import SpriteKit
import MultipeerConnectivity

extension SKNode {
    class func unarchiveFromFile(_ file : String) -> SKNode? {
        if let path = Bundle.main.path(forResource: file, ofType: "sks") {
            let sceneData = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let archiver = NSKeyedUnarchiver(forReadingWith: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, UITextFieldDelegate, MCBrowserViewControllerDelegate, MCAdvertiserAssistantDelegate {
    
    var mainMenuView : Menu!
    var settings : Settings!
    var lbView : LeaderboardView!
    var gameView : SKView!
    var scene : GameScene!
    
    // Multipeer part
    var browser : MCBrowserViewController!
    var advertiser : MCAdvertiserAssistant!
    
    // Leaderboard data
    var leaderboard : PersistentLeaderboard!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load persistent leaderboard
        if let l = NSKeyedUnarchiver.unarchiveObject(withFile: PersistentLeaderboard.ArchiveURL.path) {
            self.leaderboard = l as! PersistentLeaderboard
        } else {
            self.leaderboard = PersistentLeaderboard()
        }
        
        // Main menu view set up
        mainMenuView = Menu(frame: UIScreen.main.bounds)
        mainMenuView.startBtn.addTarget(self, action: #selector(GameViewController.startSingle), for: .touchUpInside)
        mainMenuView.multiPlayerBtn.addTarget(self, action: #selector(GameViewController.startMultiple), for: .touchUpInside)
        mainMenuView.scoreBtn.addTarget(self, action: #selector(GameViewController.showLeaderboard), for: .touchUpInside)
        mainMenuView.settingBtn.addTarget(self, action: #selector(GameViewController.showSetting), for: .touchUpInside)
        mainMenuView.nameField.delegate = self
        self.view.addSubview(mainMenuView)
        
        // Setting view set up
        settings = Settings(frame: UIScreen.main.bounds)
        settings.exitBtn.addTarget(self, action: #selector(GameViewController.exitSetting), for: .touchUpInside)
        settings.motionDetectSwitch.addTarget(self, action: #selector(GameViewController.checkMotionDetectStatus(_:)), for: UIControlEvents.valueChanged)
        settings.soundDetectSwitch.addTarget(self, action: #selector(GameViewController.checkSoundDetectStatus(_:)), for: UIControlEvents.valueChanged)
        settings.isHidden = true
        
        // Leaderboard view set up
        lbView = LeaderboardView(frame: UIScreen.main.bounds)
        lbView.exitBtn.addTarget(self, action: #selector(GameViewController.exitLeaderboard), for: .touchUpInside)
        lbView.isHidden = true
        
        mainMenuView.addSubview(settings)
        mainMenuView.addSubview(lbView)
        
        // Game view set up
        self.gameView = SKView(frame: UIScreen.main.bounds)

        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.gameView
            skView?.showsFPS = true
            skView?.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView?.ignoresSiblingOrder = true
            scene.size = (skView?.bounds.size)!
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .aspectFill
            
            skView?.presentScene(scene)
            
            self.scene = scene
            
            scene.parentView = self
        }
        self.view.insertSubview(gameView, belowSubview: mainMenuView)
        
        // Multipeer init
        self.browser = MCBrowserViewController(serviceType: "agario-ming", session: self.scene.session)
        self.browser.modalPresentationStyle = .formSheet
        self.browser.maximumNumberOfPeers = 1
        self.browser.delegate = self
        self.advertiser = MCAdvertiserAssistant(serviceType: "agario-ming", discoveryInfo: nil, session: self.scene.session)
        self.advertiser.delegate = self
    }
    
    func startSingle() {
        self.advertiser.stop()
        
        // Set Player Name
        self.scene.playerName = mainMenuView.nameField.text!
        self.mainMenuView.isHidden = true
        self.scene.start()
    }
    
    func startMultiple() {
        self.scene.playerName = mainMenuView.nameField.text!
        self.advertiser.stop()
        
        let alert = UIAlertController(title: "New Game or Existent Game", message: "Please make a decision", preferredStyle: .actionSheet)
        let masterAction = UIAlertAction(title: "Start a New Game", style: .default) { (action) in
            self.mainMenuView.isHidden = true
            self.scene.start(GameScene.GameMode.mpMaster)
            self.advertiser.start()
            alert.dismiss(animated: false, completion: { () -> Void in})
        }
        alert.addAction(masterAction)
        let clientAction = UIAlertAction(title: "Search & Join a Game", style: .default) { [unowned self, browser = self.browser] (action) in
            self.present(browser!, animated: true, completion: nil)
            alert.dismiss(animated: false, completion: { () -> Void in})
        }
        alert.addAction(clientAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            alert.dismiss(animated: false, completion: nil)
        }
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        self.mainMenuView.isHidden = true
        self.scene.start(GameScene.GameMode.mpClient)
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browser.session.disconnect()
        browserViewController.dismiss(animated: true, completion: nil)
    }

    func showSetting() {
        settings.isHidden = false
    }
    
    func exitSetting() {
        settings.isHidden = true
    }

    func showLeaderboard() {
        lbView.isHidden = false
        let l = leaderboard.getRank()
        lbView.setLeaderboardContent(l)
        print(l)
    }
    
    func exitLeaderboard() {
        lbView.isHidden = true
    }
    
    func checkMotionDetectStatus(_ mdswitch: UISwitch) {
        if mdswitch.isOn {
            self.scene.motionManager.startDeviceMotionUpdates()
            self.scene.motionDetectionIsEnabled = true
        } else {
            self.scene.motionManager.stopDeviceMotionUpdates()
            self.scene.motionDetectionIsEnabled = false
        }
    }
    
    func checkSoundDetectStatus(_ sdswitch: UISwitch) {
        if sdswitch.isOn {
            self.scene.soundDetectionIsEnabled = true
        } else {
            self.scene.soundDetectionIsEnabled = false
        }
    }
    
    override var shouldAutorotate : Bool {
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask.allButUpsideDown
        } else {
            return UIInterfaceOrientationMask.all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    /********************** UITextFieldDelegate Functions **********************/
    // Dismiss keyboard on pressing return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    // Check the maximum length of textfield
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textLength = (textField.text!.utf16).count + (string.utf16).count - range.length
        return textLength <= GlobalConstants.MaxNameLength
    }
}
