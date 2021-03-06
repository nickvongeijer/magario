//
//  Utilities.swift
//  agario
//
//  Created by Ming on 9/13/15.
//
//

import SpriteKit

extension CGVector {
    func normalize() -> CGVector {
        let d = length()
        
        return CGVector(dx: dx / d, dy: dy / d)
    }
    
    func length() -> CGFloat {
        return hypot(dx, dy)
    }
}

func *(lhs: CGVector, rhs: CGFloat) -> CGVector {
    return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
}

func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func +(lhs: CGPoint, rhs: CGVector) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
}

func +(lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
}

func -(lhs: CGPoint, rhs: CGPoint) -> CGVector {
    return CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
}

func randomColor() -> Int {
    let maxIdx = GlobalConstants.Color.count - 1
    let randi  = Int(arc4random_uniform(UInt32(maxIdx)))
    return GlobalConstants.Color[randi]
}

func randomValue() -> Int {
	return Int(arc4random_uniform(20))
}

func randomAddEquation(sum: UInt32) -> String {
	let addingValue	= arc4random_uniform(sum)
	let addedValue	= sum - addingValue
	return String(addingValue) + " + " + String(addedValue)
}

func randomSubtraction(res result: UInt32) -> String {
	
	let difference = arc4random_uniform(result)
	return String(result + difference) + " - " + String(difference)
}

func randomPosition() -> CGPoint {
    let width = UInt32(GlobalConstants.MapSize.width)
    let height = UInt32(GlobalConstants.MapSize.height)
    let pos_x = CGFloat(arc4random_uniform(width)) - CGFloat(width / 2)
    let pos_y = CGFloat(arc4random_uniform(height)) - CGFloat(height / 2)
    return CGPoint(x: pos_x, y: pos_y)
}

func scheduleRun(_ target: SKNode, time: TimeInterval, block: @escaping ()->()) {
    let waitAction = SKAction.wait(forDuration: time)
    let runAction = SKAction.run(block)
    target.run(SKAction.sequence([waitAction, runAction]))
}

func scheduleRunRepeat(_ target: SKNode, time: TimeInterval, block: @escaping ()->()) {
    let waitAction = SKAction.wait(forDuration: time)
    let runAction = SKAction.run(block)
    target.run(SKAction.repeatForever(SKAction.sequence([waitAction, runAction])))
}

func distance(_ p1 : CGPoint, p2 : CGPoint) -> CGFloat {
    let v = p1 - p2 as CGVector
    return v.length()
}

func circleOverlapArea(_ r1: CGFloat, r2: CGFloat, d: CGFloat) -> CGFloat {
    if d >= r1 + r2 {
        return 0
    }
    if r2 + d <= r1 {
        return circleArea(r2)
    }
    //let t = (d * d - r2 * r2 + r1 * r1) * (d * d - r2 * r2 + r1 * r1)
    //let a = 1.0 / d * sqrt(4 * d * d * r1 * r1 - t)
    let d1 = (d * d - r2 * r2 + r1 * r1) / (2 * d)
    let d2 = (d - d1)
	
	func f(_ rr : CGFloat,_ dd : CGFloat) -> CGFloat {
		return rr * rr * acos(dd / rr) - dd * sqrt(rr * rr - dd * dd)
	}
	
    return f(r1, d1) + f(r2, d2)
}

func circleArea(_ r : CGFloat) -> CGFloat {
    return CGFloat(M_PI) * r * r
}

func colorToHex(_ color: UIColor) -> Int {
    let rgb = color.cgColor.components
    let r = Int(255.0 * (rgb?[0])!)
    let g = Int(255.0 * (rgb?[1])!)
    let b = Int(255.0 * (rgb?[2])!)
    let c = (r << 16) + (g << 8) + b
    return c
}
