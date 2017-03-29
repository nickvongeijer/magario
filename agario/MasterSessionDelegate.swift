//
//  MasterSessionDelegate.swift
//  agario
//
//  Created by Ming on 10/4/15.
//
//

import SpriteKit
import MultipeerConnectivity

class MasterSessionDelegate : NSObject, MCSessionDelegate {
    
    var scene : GameScene!
    var session : MCSession!
    
    var userDict : Dictionary<MCPeerID, String> = Dictionary<MCPeerID, String>()
    
    // A hack to improve performance
    var foodMask : Int = 0
    
    init(scene : GameScene, session : MCSession) {
        self.scene = scene
        self.session = session
    }
    
    func broadcast() {
        if self.session.connectedPeers.count == 0 {
            return
        }
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
            var json : JSON = ["type": "BROADCAST" as AnyObject]
            
            // Food & a hack to improve performance
            if self.foodMask == 0 {
                var foodArray : [JSON] = []
                for f in self.scene.foodLayer.children as! [Food] {
                    foodArray.append(f.toJSON())
                }
                json["foods"] = JSON(foodArray)
            }
            self.foodMask = (self.foodMask + 1) % 4
            
            // Players & Balls
            var playerArray : [JSON] = []
            for f in self.scene.playerLayer.children as! [Player] {
                playerArray.append(f.toJSON())
            }
            json["players"] = JSON(playerArray)
            
            // Barriers
            var barrierArray : [JSON] = []
            for f in self.scene.barrierLayer.children as! [Barrier] {
                barrierArray.append(f.toJSON())
            }
            json["barriers"] = JSON(barrierArray)
            
            do {
                try self.session.send(json.rawData(), toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            } catch let e as NSError {
                print(e)
            }
        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let json = JSON(data: data)
        //print("Got something in master\n", json)
        if json["type"].stringValue == "SPAWN" {
            DispatchQueue.main.async(execute: {
                let p = Player(playerName: json["name"].stringValue, playerValue: json["value"].intValue, parentNode: self.scene.playerLayer, initPosition: randomPosition())
                let response : JSON = ["type": "SPAWN", "ID": p.name!]
                self.userDict[peerID] = p.name!
                do {
                    print("Sending spawn info to ", peerID, "info: ", response["ID"].stringValue)
                    try self.session.send(response.rawData(), toPeers: [peerID], with: MCSessionSendDataMode.reliable)
                } catch let e as NSError {
                    print("Something wrong when sending SPAWN info back", e)
                }
            })

//            let p = Player(playerName: json["name"].stringValue, parentNode: self.scene.playerLayer, initPosition: randomPosition())
//            let response : JSON = ["type": "SPAWN", "ID": p.name!]
//            userDict[peerID] = p.name!
//            do {
//                try self.session.sendData(response.rawData(), toPeers: [peerID], withMode: MCSessionSendDataMode.Reliable)
//            } catch let e as NSError {
//                print("Something wrong when sending SPAWN info back", e)
//            }
        }
        if json["type"].stringValue == "MOVE" {
            let p : CGPoint = CGPoint(x: json["x"].doubleValue, y: json["y"].doubleValue)
            if let nm = userDict[peerID] {
                if let nd = scene.playerLayer.childNode(withName: nm) {
                    let player = nd as! Player
                    DispatchQueue.main.async(execute: {
                        player.move(p)
                    })
                    //player.move(p)
                }
            }
        }
        if json["type"].stringValue == "FLOATING" {
            if let nm = userDict[peerID] {
                if let nd = scene.playerLayer.childNode(withName: nm) {
                    let player = nd as! Player
                    DispatchQueue.main.async(execute: {
                        player.floating()
                    })
                    //player.floating()
                }
            }
        }
        if json["type"].stringValue == "SPLIT" {
            if let nm = userDict[peerID] {
                if let nd = scene.playerLayer.childNode(withName: nm) {
                    let player = nd as! Player
                    DispatchQueue.main.async(execute: {
                        player.split()
                    })
                    //player.split()
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    }
}
