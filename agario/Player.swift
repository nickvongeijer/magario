//
//  Player.swift
//  agario
//
//  Created by Yunhan Li on 9/15/15.
//
//

import SpriteKit
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
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class Player : SKNode {
    
    var displayName : String	= ""
	var playerValue : Int?	= nil
    
	init(playerName name : String, playerValue value : Int, parentNode parent : SKNode, initPosition p : CGPoint) {
        super.init()
        self.position = CGPoint(x: 0, y: 0)
        
        self.displayName = name
		self.playerValue = value
        self.name = "player-" + UUID().uuidString
        
		let ball = Ball(ballName: name, ballValue: value)
        ball.position = p
        self.addChild(ball)
        
        //self.zPosition = GlobalConstants.ZPosition.ball
        
        parent.addChild(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
	convenience init(playerName name : String, playerValue: Int, parentNode parent : SKNode) {
		self.init(playerName: name, playerValue: playerValue, parentNode: parent, initPosition: CGPoint(x: 0, y: 0))
    }
    
    func centerPosition() -> CGPoint {
        //let count = CGFloat(self.children.count)
        var x = CGFloat(0)
        var y = CGFloat(0)
        let m = self.totalMass()
        for ball in self.children as! [Ball] {
            x += ball.position.x * ball.mass / m
            y += ball.position.y * ball.mass / m
        }
        return CGPoint(x: x, y: y)
    }
    
    func totalMass() -> CGFloat {
        var ret : CGFloat = 0
        for ball in self.children as! [Ball] {
            ret += ball.mass
        }
        return ret
    }
    
    func move(_ pos : CGPoint) {
        for ball in self.children as! [Ball] {
            ball.moveTowardTarget(targetLocation: pos)
        }
    }
    
    func floating() {
        for ball in self.children as! [Ball] {
            ball.targetDirection = CGVector(dx:0, dy: 0)
        }
    }
    
    // Potentially used for AI and online player
    func refreshState() {
        for ball in self.children as! [Ball] {
            ball.refresh()
        }
    }
    
    func checkDeath() {
        if self.children.count == 0 {
            self.removeFromParent()
        }
    }
    
    func isDead() -> Bool {
        return self.children.count == 0
    }
    
    func split() {
        for ball in self.children as! [Ball] {
            if self.children.count < 15 && ball.mass >= 25 {
                ball.split()
            }
        }
    }
    
    func toJSON() -> JSON {
        var json : JSON = ["name": self.name! as AnyObject, "displayName" : self.displayName as AnyObject]
        var jsonArray : [JSON] = []
        for ball in self.children as! [Ball] {
            jsonArray.append(ball.toJSON())
        }
        json["balls"] = JSON(jsonArray)
        return json
    }
}
