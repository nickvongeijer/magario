//
//  Ball.swift
//  agar-clone
//
//  Created by Ming on 9/13/15.
//
//

import SpriteKit

class Ball : SKShapeNode {
    var targetDirection = CGVector(dx: 0, dy: 0)
    var maxVelocity     = CGFloat(200.0)
    var force           = CGFloat(5000.0)
    var radius          = CGFloat(0)
    var color:Int?      = nil
    var mass : CGFloat!
    var ballName : String?
	var ballValue: Int? = nil
    var readyMerge = false
    var impulsive = true
    var contacted : Set<SKNode> = []
    var nameLabel : SKLabelNode? = nil
    
	init(ballName name : String?, ballValue value : Int, ballColor color : Int, ballMass mass : CGFloat, ballPosition pos : CGPoint) {
        super.init()
        self.name   = "ball-" + UUID().uuidString
        self.ballName = name
		self.ballValue = value
        self.color  = color
        self.position = pos
        self.setMass(mass)
        
        //Graphic
        self.drawBall()
        self.setBallSkin()
        // Physics
        self.initPhysicsBody()
        
        self.zPosition = self.mass
        
        // Name label
        if let nm = self.ballValue {
            self.nameLabel = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
//            self.nameLabel!.text = String(nm)
			self.nameLabel?.text = randomAddEquation(sum: UInt32(nm))
            self.nameLabel!.fontSize = 16
            self.nameLabel!.horizontalAlignmentMode = .center
            self.nameLabel!.verticalAlignmentMode = .center
            self.addChild(self.nameLabel!)
        }
		
        self.resetReadyMerge()
        scheduleRun(self, time: 0.5) { () -> Void in
            self.impulsive = false
        }
    }
    
	convenience init(ballName name : String, ballValue value : Int) {
		self.init(ballName: name, ballValue: value, ballColor: randomColor(), ballMass: 10, ballPosition : CGPoint(x: 0, y: 0))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setMass(_ m : CGFloat) {
        self.mass = m
        self.zPosition = m
        self.force = 5000.0 * self.mass / 10.0
        self.maxVelocity = 200.0 / log10(self.mass)
        self.radius = sqrt(m) * 10.0
        
        if let nl = self.nameLabel {
            nl.fontSize = max(self.radius / 3, 15)
        }
    }
    
    func drawBall() {
        let diameter = self.radius * 2
        self.path = CGPath(ellipseIn: CGRect(origin: CGPoint(x: -self.radius, y: -self.radius), size: CGSize(width: diameter, height: diameter)), transform: nil)
    }
    
    func setBallSkin() {
        let _ballname = self.ballName!.lowercased()
        if GlobalConstants.Skin.index(forKey: _ballname) != nil{
            self.fillColor = UIColor.white
            self.fillTexture = SKTexture(imageNamed: GlobalConstants.Skin[_ballname]!)
        } else {
            self.fillColor = UIColor(hex: self.color!)
        }
    }
    
    func initPhysicsBody() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.mass = mass
        self.physicsBody?.friction = 1000
        self.physicsBody?.restitution = 1
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.categoryBitMask = GlobalConstants.Category.ball
        self.physicsBody?.collisionBitMask = GlobalConstants.Category.wall
        self.physicsBody?.contactTestBitMask = GlobalConstants.Category.barrier | GlobalConstants.Category.ball
        //self.zPosition = GlobalConstants.ZPosition.ball
    }
    
    func regulateSpeed() {
        if self.impulsive {
            return
        }
        let v = self.physicsBody?.velocity
        
        if v!.dx * v!.dx + v!.dy * v!.dy > maxVelocity * maxVelocity {
            self.physicsBody?.velocity = v!.normalize() * maxVelocity
            //self.physicsBody?.velocity = v! * 0.99
        }
    }
    
    func refresh() {
        if targetDirection.dx * targetDirection.dx + targetDirection.dy * targetDirection.dy > radius * radius {
            self.physicsBody?.applyForce(targetDirection.normalize() * force)
            //self.physicsBody?.velocity = targetDirection.normalize() * maxVelocity
        } else {
            if !impulsive {
                self.physicsBody?.velocity = (self.physicsBody?.velocity)! * CGFloat(0.9)
            }
        }
        
        for node in contacted {
            if node.parent == nil || !node.inParentHierarchy(node.parent!) {
                // Node eaten by other nodes
                contacted.remove(node)
            }
            if (node.name!.hasPrefix("ball")) {
                let ball = node as! Ball
                if ball.parent == self.parent { // Sibling
                    if self.readyMerge && ball.readyMerge {
                        self.mergeBall(ball)
                        contacted.remove(node)
                    } else {
                        // Keep distance between nodes
                        let d = distance(self.position, p2: ball.position)
                        if d < self.radius + ball.radius {
                            let v = (self.position - ball.position).normalize()
                            let f = (self.force * 0.90) * (1 - (d / (self.radius + ball.radius))) + self.force * 0.10
                            self.physicsBody?.applyForce(v * f)
                            ball.physicsBody?.applyForce(v * -1 * f)
                        }
                     }
                } else { // Enemy
                    if self.mass - ball.mass > max(ball.mass * 0.05, 10) {
                        let d = distance(self.position, p2: ball.position)
                        let a = circleOverlapArea(self.radius, r2: ball.radius, d: d)
                        if a > 0 && a > circleArea(ball.radius) * 0.75 && self.ballValue == ball.ballValue {
                            self.eatBall(ball)
                            contacted.remove(node)
                        }
                    }
                }
            } else if (node.name!.hasPrefix("food")) {
                if self.contains(node.position) {
					if (node as! Food).sufValue == self.ballValue {
						
						var update = false
						if (node.parent?.children as! [Food]).filter({$0.sufValue == self.ballValue}).count <= 3 {
							update = true
						}
						self.eatFood(node as! Food, update: update)
						contacted.remove(node)
					}
                }
            }
        }
    }
    
    func moveTowardTarget(targetLocation loc:CGPoint) {
        targetDirection = loc - self.position
    }
    
    func split(_ n : Int = 2) {
        if n <= 1 {
            return
        }
        if let p = self.parent {
            var newballs : [Ball] = []
            for _ in 0..<n {
				newballs.append(Ball(ballName: self.ballName, ballValue: randomValue(), ballColor: self.color!,
                    ballMass: floor(self.mass / CGFloat(n)), ballPosition: self.position))
            }
            if let v = self.physicsBody?.velocity {
                var i = 0
                for ball in newballs {
                    ball.physicsBody?.velocity = v
                    if n > 2 && i > 0 {
                        ball.physicsBody?.velocity = (randomPosition() - self.position).normalize() * ball.maxVelocity
                    }
                    i += 1
                }
                if n == 2 {
                    newballs[1].physicsBody?.velocity = v.normalize() * self.radius * 8 * (1 / log10(self.mass))
                }
            }
            self.removeFromParent()
            for ball in newballs {
                p.addChild(ball)
            }
        }
    }
    
	func eatFood(_ food : Food, update: Bool) {
        // Destroy the food been eaten
        food.removeFromParent()
        self.setMass(self.mass! + 1)
        self.drawBall()
        let oldv = self.physicsBody?.velocity
        self.initPhysicsBody()
        self.physicsBody?.velocity = oldv!
		
		if update {
			self.ballValue = randomValue()
			self.nameLabel?.text = randomAddEquation(sum: UInt32(self.ballValue!))
			self.color = GlobalConstants.Color[self.ballValue!]
			self.fillColor = UIColor.init(hex: self.color!)
		}
    }
    
    func resetReadyMerge() {
        self.readyMerge = false
        scheduleRun(self, time: 30) { () -> Void in
            self.readyMerge = true
        }
    }
    
    func mergeBall(_ ball : Ball) {
        self.eatBall(ball)
        self.resetReadyMerge()
    }
    
    func eatBall(_ ball : Ball) {
        ball.removeFromParent()
        self.setMass(self.mass! + ball.mass * 2)
        self.drawBall()
        let oldv = self.physicsBody?.velocity
        self.initPhysicsBody()
        self.physicsBody?.velocity = oldv!
        //self.physicsBody?.velocity = oldv!.normalize() * self.maxVelocity
    }
    
    func beginContact(_ node : SKNode) {
        contacted.insert(node)
    }
    
    func endContact(_ node : SKNode) {
        contacted.remove(node)
    }
    
    func toJSON() -> JSON {
        let v = self.physicsBody?.velocity
        let x = Double(self.position.x)
        let y = Double(self.position.y)
        let dx = Double(v!.dx)
        let dy = Double(v!.dy)
        let mass = Double(self.mass)
        let json : JSON = ["name": self.name! as AnyObject, "ballName": self.ballName! as AnyObject, "color": self.color! as AnyObject, "mass": mass as AnyObject, "x": x as AnyObject, "y": y as AnyObject, "dx": dx as AnyObject, "dy": dy, "tdx": Double(self.targetDirection.dx), "tdy": Double(self.targetDirection.dy)]
        return json
    }
}
