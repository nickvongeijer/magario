//
//  GameScene.swift
//  agar-clone
//
//  Created by Ming on 8/24/15.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

import SpriteKit
import CoreMotion
import MultipeerConnectivity
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class GameScene: SKScene {
    
    enum GameMode {
        case sp // Single player
        case mpMaster // Multi player master
        case mpClient // Multi player client
    }
    
    var parentView : GameViewController!
    
    var world : SKNode!
    var foodLayer : SKNode!
    var barrierLayer : SKNode!
    var playerLayer : SKNode!
    var hudLayer : Hud!
    var background : SKSpriteNode!
    var defaultBackgroundColor : UIColor!
    
    var currentPlayer: Player? = nil
    var rank : [Dictionary<String, Any>] = []
    var playerName = ""
    var splitButton : SKSpriteNode!
    var currentMass : SKLabelNode!
    
    var touchingLocation : UITouch? = nil
    var motionManager : CMMotionManager!
    var motionDetectionIsEnabled = false
    var soundDetector : SoundController!
    var soundDetectionIsEnabled = false
    
    // Menus
    var pauseMenu : PauseView!
    var gameOverMenu : GameOverView!
    
    var gameMode : GameMode! = GameMode.sp
    
    // Multipeer variables
    var session : MCSession!
    var clientDelegate : ClientSessionDelegate!
    var masterDelegate : MasterSessionDelegate!
    
    override func didMove(to view: SKView) {
        isPaused = true
        self.view?.isMultipleTouchEnabled = true
        
        // Prepare multipeer connectivity
        session = MCSession(peer: MCPeerID(displayName: UIDevice.current.name))
        clientDelegate = ClientSessionDelegate(scene: self, session: session)
        masterDelegate = MasterSessionDelegate(scene: self, session: session)
        
        world = self.childNode(withName: "world")!
        foodLayer = world.childNode(withName: "foodLayer")
        barrierLayer = world.childNode(withName: "barrierLayer")
        playerLayer = world.childNode(withName: "playerLayer")
        background = world.childNode(withName: "//background") as! SKSpriteNode
        defaultBackgroundColor = background.color
        
        /* Setup your scene here */
        world.position = CGPoint(x: frame.midX,
            y: frame.midY)
 
        // Setup Hud
        hudLayer = Hud(hudWidth: self.frame.width, hudHeight: self.frame.height)
        self.addChild(hudLayer)
        physicsWorld.contactDelegate = self
        
        // Setup pause menu and death menu
        pauseMenu = PauseView(frame: self.frame, scene: self)
        self.view!.addSubview(pauseMenu)
        gameOverMenu = GameOverView(frame: self.frame, scene: self)
        self.view!.addSubview(gameOverMenu)
        
        // Device motion detector
        motionManager = CMMotionManager()
        
        // Sound Detector
        soundDetector = SoundController()
    }
    
    func cleanAll() {
        foodLayer.removeAllChildren()
        barrierLayer.removeAllChildren()
        playerLayer.removeAllChildren()
        
        self.removeAllActions()
        self.background.removeAllActions()
    }
    
    func start(_ gameMode : GameMode = GameMode.sp) {
        // set background to default color
        self.background.color = self.defaultBackgroundColor
        
        self.gameMode = gameMode
        
        cleanAll()
        
        scheduleRunRepeat(self, time: Double(GlobalConstants.LeaderboardUpdateInterval)) { () -> Void in
            self.updateLeaderboard()
        }
        
        scheduleRunRepeat(self, time: Double(GlobalConstants.PersistentLeaderboardUpdateInterval)) { () -> Void in
            self.parentView.leaderboard.save()
        }
        
        if gameMode == GameMode.sp || gameMode == GameMode.mpMaster {
            // Create Foods
            self.spawnFood(GlobalConstants.FoodLimit)
            // Create Barriers
            self.spawnBarrier(GlobalConstants.BarrierLimit)
            
            scheduleRunRepeat(self, time: Double(GlobalConstants.BarrierRespawnInterval)) { () -> Void in
                if self.barrierLayer.children.count < GlobalConstants.BarrierLimit {
                    self.spawnBarrier()
                }
            }
            
            self.currentPlayer = Player(playerName: playerName, playerValue: randomValue(), parentNode: self.playerLayer)
        }
        
        // Spawn AI for single player mode
        if gameMode == GameMode.sp {
            for _ in 0..<GlobalConstants.StupidPlayerCount {
				let _ = StupidPlayer(playerName: "Stupid AI", playerValue: randomValue(), parentNode: self.playerLayer)
            }
            for i in 0..<GlobalConstants.SmarterPlayerCount {
                let _ = AIPlayer(playerName: GlobalConstants.SkinName[i], playerValue: randomValue(), parentNode: self.playerLayer)
            }
        }
        
        if gameMode != GameMode.sp {
            if gameMode == GameMode.mpMaster {
                session.delegate = masterDelegate
                scheduleRunRepeat(self, time: Double(GlobalConstants.BroadcastInterval)) { () -> Void in
                    self.masterDelegate.broadcast()
                }
            }
            if gameMode == GameMode.mpClient {
                session.delegate = clientDelegate
                clientDelegate.requestSpawn()
            }
        }
        
        // Start recording if sound detection is enabled
        if soundDetectionIsEnabled {
            soundDetector.startRecording()
            print("recording")
        }

        scheduleRunRepeat(self, time: Double(GlobalConstants.SoundUpateInterval)) { () -> Void in
            if self.soundDetectionIsEnabled {
                let db = self.soundDetector.update()
                self.changeBackground(db)
            }
        }
        
        self.updateLeaderboard()
        
        isPaused = false
    }
    
    func pauseGame() {
        self.pauseMenu.isHidden = false
        
        // Only pause in SP mode
        if gameMode == GameMode.sp {
            self.isPaused = true
        }
    }
    
    func continueGame() {
        self.pauseMenu.isHidden = true
        self.isPaused = false
    }
    
    func abortGame() {
        if soundDetectionIsEnabled {
            self.soundDetector.stopRecording()        
        }
        self.isPaused = true
        self.pauseMenu.isHidden = true
        self.gameOverMenu.isHidden = true
        self.parentView.mainMenuView.isHidden = false
        
        self.session.disconnect()
    }
    
    func gameOver() {
        if gameMode == GameMode.sp {
            // Pause only in SP mode
            //self.paused = true
        }
        
        self.gameOverMenu.isHidden = false
    }
    
    func respawn() {
        self.isPaused = false
        self.gameOverMenu.isHidden = true
        if gameMode == GameMode.sp || gameMode == GameMode.mpMaster {
            if currentPlayer == nil || currentPlayer!.isDead() {
				currentPlayer = Player(playerName: playerName, playerValue: randomValue(), parentNode: self.playerLayer)
                currentPlayer!.children.first!.position = randomPosition()
            }
        } else {
            // Send request to server
            self.clientDelegate.requestSpawn()
        }
    }
    
    func spawnFood(_ n : Int = 1) {
        for _ in 0..<n {
			foodLayer.addChild(Food(value: randomValue()))
        }
    }
    
    func spawnBarrier(_ n : Int = 1) {
        for _ in 0..<n {
            barrierLayer.addChild(Barrier())
        }
    }
    
    func changeBackground(_ db: Float) {
        if db < -GlobalConstants.minumDecibel {
            background.run(SKAction.colorize(with: UIColor(hex:0x30393b), colorBlendFactor: 1.0, duration: 3.0))
        } else {
            let r = defaultBackgroundColor.components.red
            let g = defaultBackgroundColor.components.green
            let b = defaultBackgroundColor.components.blue
            let color = UIColor(red: dbMapToColor(db, color: r), green: dbMapToColor(db, color: g), blue: dbMapToColor(db, color: b),alpha: 1)
            background.run(SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: 2.0))
        }
    }
    
    func dbMapToColor(_ db: Float, color: CGFloat) -> CGFloat{
        return color * CGFloat((db + GlobalConstants.minumDecibel) / GlobalConstants.minumDecibel)
    }
    
    func updateLeaderboard() {
        rank = []
        for player in playerLayer.children as! [Player] {
            rank.append([
                "name": player.displayName,
                "score": player.totalMass()
            ])
        }
        
        if gameMode == GameMode.sp { // Only put self score into leaderboard
            if currentPlayer != nil {
                self.parentView.leaderboard.updateRank([["name" : currentPlayer!.displayName,
                    "score": currentPlayer!.totalMass()]])
            }
        } else {
            self.parentView.leaderboard.updateRank(rank)
        }
        
        rank.sort(by: {$0["score"] as! CGFloat > $1["score"] as! CGFloat})

        hudLayer.setLeaderboard(lst: rank)
    }
    
    func centerWorldOnPosition(_ position: CGPoint) {
        let screenLocation = self.convert(position, from: world)
        let screenCenter = CGPoint(x: frame.midX, y: frame.midY)
        world.position = world.position - screenLocation + screenCenter
    }
    
    func scaleWorldBasedOnPlayer(_ player : Player) {
        if player.children.count == 0 || player.totalMass() == 0 {
            world.setScale(1.0)
            return
        }
        let scaleFactorBallNumber = 1.0 + (log(CGFloat(player.children.count)) - 1) * 0.2
        let t = log10(CGFloat(player.totalMass())) - 1
        let scaleFactorBallMass = 1.0 + t * t * 1.0
		
        world.setScale(max(1 / scaleFactorBallNumber / scaleFactorBallMass, 0.7))
    }
    
    func motionDetection() -> CGVector? {
        if let motion = motionManager.deviceMotion {
            //motion.attitude.yaw
            let m = motion.attitude.rotationMatrix
            let x = Vector3D(x: m.m11, y: m.m12, z: m.m13)
            let y = Vector3D(x: m.m21, y: m.m22, z: m.m23)
            let z = Vector3D(x: m.m31, y: m.m32, z: m.m33)
            
            let g = Vector3D(x: 0.0, y: 0.0, z: -1.0)
            let pl = dot(z, rhs: g)
            var d = g - z * pl
            d = d / d.length()
            
            let nd = CGVector(dx: dot(d, rhs: y), dy: -1.0 * dot(d, rhs: x))
            let maxv : CGFloat = 10000.0
            return nd * maxv
        }
        return nil
    }
    
    override func didSimulatePhysics() {

        world.enumerateChildNodes(withName: "//ball*", using: {
            node, stop in
            let ball = node as! Ball
            ball.regulateSpeed()
        })
        
        if let p = currentPlayer {
            centerWorldOnPosition(p.centerPosition())
        } else if playerLayer.children.count > 0 {
            let p = playerLayer.children.first! as! Player
            centerWorldOnPosition(p.centerPosition())
        } else {
            centerWorldOnPosition(CGPoint(x: 0, y: 0))
        }
    }
   
    override func update(_ currentTime: TimeInterval) {
        if isPaused {
            return
        }
        
        if gameMode == GameMode.mpClient {
            clientDelegate.updateScene()
        }
        
        if gameMode != GameMode.mpClient {
            // Respawn food and barrier
            let fl = gameMode == GameMode.sp ? GlobalConstants.FoodLimit : 250
            let foodRespawnNumber = min(fl - foodLayer.children.count, GlobalConstants.FoodRespawnRate)
            spawnFood(foodRespawnNumber)
        }
        
        if currentPlayer != nil {
            if let t = touchingLocation {
                let p = t.location(in: world)
                if gameMode == GameMode.mpClient {
                    clientDelegate.requestMove(p)
                }
                currentPlayer!.move(p)
            } else {
                if gameMode == GameMode.mpClient {
                    clientDelegate.requestFloating()
                }
                currentPlayer!.floating()
            }
            
            let v = motionDetection()
            if motionDetectionIsEnabled && v != nil {
                let c = currentPlayer!.centerPosition()
                let p = CGPoint(x: c.x + v!.dx, y: c.y + v!.dy)
                if gameMode == GameMode.mpClient {
                    clientDelegate.requestMove(p)
                }
                currentPlayer!.move(p)
            }
        } else {
            // Send request to server
        }
		
		for i in stride(from:playerLayer.children.count - 1, to: 0, by: -1) {
			let p = playerLayer.children[i] as! Player
			p.checkDeath()
		}
//        for var i = playerLayer.children.count - 1; i >= 0; i -= 1 {
//            let p = playerLayer.children[i] as! Player
//            p.checkDeath()
//        }
		
        if currentPlayer != nil && currentPlayer!.isDead() {
            self.gameOver()
            currentPlayer = nil
        }
        
        for p in playerLayer.children as! [Player] {
            p.refreshState()
        }
        
        if currentPlayer != nil {
            hudLayer.setScore(currentPlayer!.totalMass())
            scaleWorldBasedOnPlayer(currentPlayer!)
        } else if playerLayer.children.count > 0 {
            scaleWorldBasedOnPlayer(playerLayer.children.first! as! Player)
        } else {
            world.setScale(1.0)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count <= 0 || isPaused {
            return
        }
        
        for touch in touches {
            let screenLocation = touch.location(in: self)
            if self.hudLayer.splitBtn.contains(screenLocation) {
                if currentPlayer != nil {
                    currentPlayer!.split()
                    if gameMode == GameMode.mpClient {
                        clientDelegate.requestSplit()
                    }
                }
            } else if self.hudLayer.pauseBtn.contains(screenLocation) {
                self.pauseGame()
            } else {
                touchingLocation = touch
            }
        }
        
        if let t = touchingLocation {
            let screenLocation = t.location(in: self)
            if screenLocation.x > frame.width * 0.7 {
                hudLayer.moveSplitButtonToLeft()
            }
            if screenLocation.x < frame.width * 0.3 {
                hudLayer.moveSplitButtonToRight()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count <= 0 || isPaused {
            return
        }
        
        for touch in touches {
            let screenLocation = touch.location(in: self)
            if self.hudLayer.splitBtn.contains(screenLocation) {
            } else {
                touchingLocation = touch
            }
        }
        
        if let t = touchingLocation {
            let screenLocation = t.location(in: self)
            if screenLocation.x > frame.width * 0.7 {
                hudLayer.moveSplitButtonToLeft()
            }
            if screenLocation.x < frame.width * 0.3 {
                hudLayer.moveSplitButtonToRight()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count <= 0 || isPaused {
            return
        }
        
        touchingLocation = nil
    }
}

//Contact Detection
extension GameScene : SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        var fstBody : SKPhysicsBody
        var sndBody : SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            fstBody = contact.bodyA
            sndBody = contact.bodyB
        } else {
            fstBody = contact.bodyB
            sndBody = contact.bodyA
        }
        
        // Purpose of using "if let" is to test if the object exist
        if let fstNode = fstBody.node {
            if let sndNode = sndBody.node {
                if fstNode.name!.hasPrefix("ball") && sndNode.name!.hasPrefix("barrier") {
                    let nodeA = fstNode as! Ball
                    let nodeB = sndNode as! Barrier
                    if nodeA.radius >= nodeB.radius {
                        if let p = nodeA.parent {
                            nodeA.split(min(4, 16 - p.children.count + 1))
                            sndNode.removeFromParent()
                        }
                    }
                }
                if fstNode.name!.hasPrefix("food") && sndNode.name!.hasPrefix("ball") {
                    let ball = sndNode as! Ball
                    ball.beginContact(fstNode as! Food)
                }
                
                if fstNode.name!.hasPrefix("ball") && sndNode.name!.hasPrefix("ball") {
                    var ball1 = fstNode as! Ball // Big
                    var ball2 = sndNode as! Ball // Small
                    if ball2.mass > ball1.mass {
                        let tmp = ball2
                        ball2 = ball1
                        ball1 = tmp
                    }
                    ball1.beginContact(ball2)
                }
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        var fstBody : SKPhysicsBody
        var sndBody : SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            fstBody = contact.bodyA
            sndBody = contact.bodyB
        } else {
            fstBody = contact.bodyB
            sndBody = contact.bodyA
        }
        if let fstNode = fstBody.node {
            if let sndNode = sndBody.node {
                if fstNode.name!.hasPrefix("food") && sndNode.name!.hasPrefix("ball") {
                    let ball = sndNode as! Ball
                    ball.endContact(fstNode as! Food)
                }
                
                if fstNode.name!.hasPrefix("ball") && sndNode.name!.hasPrefix("ball") {
                    var ball1 = fstNode as! Ball // Big
                    var ball2 = sndNode as! Ball // Small
                    if ball2.mass > ball1.mass {
                        let tmp = ball2
                        ball2 = ball1
                        ball1 = tmp
                    }
                    ball1.endContact(ball2)
                }
            }
        }
    }
}
