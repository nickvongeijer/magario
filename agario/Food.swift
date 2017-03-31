//
//  Food.swift
//  agario
//
//  Created by Yunhan Li on 9/15/15.
//
//
import SpriteKit
import UIKit

class Food : SKSpriteNode {
    
    var radius = GlobalConstants.FoodRadius
	var sufValue: Int = 0
    static var counter : Int = 0
    
	init(value: Int){
        //super.init()
        super.init(texture: nil, color: UIColor.init(hex: GlobalConstants.Color[value % GlobalConstants.Color.count]), size: CGSize(width: radius * 2, height: radius * 2))
//		super.init(texture: nil, color: UIColor.clear, size: CGSize(width: radius * 2, height: radius * 2))
		self.name  = "food-" + UUID().uuidString
		self.sufValue = value
		
		let label = SKLabelNode(fontNamed: "Avenir")
		label.text = String(value)
		label.fontSize = 18
		label.fontColor = UIColor.black
		label.position = CGPoint(x: 0, y: -radius + 3)
		self.addChild(label)
		
		let diameter = radius * 2
		let path = CGPath.init(roundedRect: CGRect.init(x: -radius, y: -radius, width: diameter, height: diameter), cornerWidth: radius, cornerHeight: radius, transform: nil)
		self.physicsBody = SKPhysicsBody.init(edgeLoopFrom: path)//        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        //self.fillColor = UIColor(hex: color)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = GlobalConstants.Category.food
        self.physicsBody?.collisionBitMask = GlobalConstants.Category.wall
        self.physicsBody?.contactTestBitMask = GlobalConstants.Category.ball | GlobalConstants.Category.barrier
        self.zPosition = GlobalConstants.ZPosition.food
        
        self.position = randomPosition()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toJSON() -> JSON {
        let json : JSON = ["name": self.name! as AnyObject, "color": colorToHex(self.color) as AnyObject,
            "x": Double(self.position.x), "y": Double(self.position.y)]
        return json
    }
}
