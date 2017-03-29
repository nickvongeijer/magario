//
//  GameOverView.swift
//  agario
//
//  Created by Ming on 10/4/15.
//
//

import SpriteKit

class GameOverView: UIView {
    
    var backButton : UIButton!
    var respawnButton : UIButton!
    var label : UILabel!
    var scene : GameScene!
    
    init(frame: CGRect, scene: GameScene) {
        super.init(frame: frame)
        self.scene = scene
        setup()
    }
    
    func setup() {
        let width       = frame.width
        let height      = frame.height
        
        self.isHidden = true
        
        // Semi-Opacity Background
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        label = UILabel()
        label.text = "You are eaten :<"
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.white
        label.font = UIFont(name: "Chalkduster", size: label.font.pointSize * 1.5)
        label.sizeToFit()
        let labelWidth = label.frame.width
        let labelHeight = label.frame.height
        label.frame.origin = CGPoint(x: width / 2 - labelWidth / 2, y: height / 4 - labelHeight / 2)
        self.addSubview(label)
        
        let buttonWidth = width / 5
        let buttonHeight = height / 5
        
        backButton = UIButton(frame: CGRect(x: width / 2 - buttonWidth / 2, y: 3 * height / 4 - buttonHeight / 2,
            width: buttonWidth, height: buttonHeight))
        backButton.setTitle("Quit Game", for: UIControlState())
        backButton.addTarget(scene, action: "abortGame", for: UIControlEvents.touchUpInside)
        self.addSubview(backButton)
        
        respawnButton = UIButton(frame: CGRect(x: width / 2 - buttonWidth / 2, y: height / 2 - buttonHeight / 2,
            width: buttonWidth, height: buttonHeight))
        respawnButton.setTitle("Respawn", for: UIControlState())
        respawnButton.addTarget(scene, action: "respawn", for: UIControlEvents.touchUpInside)
        self.addSubview(respawnButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
