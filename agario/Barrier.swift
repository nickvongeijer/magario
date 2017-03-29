//
//  Barrier.swift
//  agario
//
//  Created by Yunhan Li on 9/18/15.
//
//

import SpriteKit

class Barrier : SKSpriteNode {
    var radius = GlobalConstants.BarrierRadius
    
    init() {
        super.init(texture: SKTexture(imageNamed: "barrier"),
            color: SKColor.white,
            size: CGSize(width: 2 * radius, height: 2 * radius))
        self.name   = "barrier-" + UUID().uuidString
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = GlobalConstants.Category.barrier
        self.physicsBody?.collisionBitMask = GlobalConstants.Category.wall | GlobalConstants.Category.barrier
        self.physicsBody?.contactTestBitMask = GlobalConstants.Category.ball | GlobalConstants.Category.food
        self.zPosition = GlobalConstants.ZPosition.barrier
        
        self.position = randomPosition()
        
        // Let barrier spin
        let spin = SKAction.rotate(byAngle: CGFloat(M_PI*2), duration: 10)
        self.run(SKAction.repeatForever(spin))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toJSON() -> JSON {
        let json : JSON = ["name": self.name! as AnyObject, "x": Double(self.position.x) as AnyObject, "y": Double(self.position.y) as AnyObject]
        return json
    }
}
