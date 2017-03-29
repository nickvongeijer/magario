//
//  PersistentLeaderborad.swift
//  agario
//
//  Created by Ming on 10/12/15.
//
//

import Foundation
import SpriteKit

class PersistentLeaderboard : NSObject, NSCoding {
    
    var rank : Dictionary<String, CGFloat> = [:]
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("rank")
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(rank, forKey: "rank")
    }
    
    override init() {
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        if let r = aDecoder.decodeObject(forKey: "rank") {
            self.rank = r as! Dictionary<String, CGFloat>
        }
        
        super.init()
    }
    
    func updateRank(_ newrank : [Dictionary<String, Any>]) {
        for k in newrank {
            var nm = k["name"] as! String
            if nm == "" {
                nm = "Anonymous"
            }
            if let s = rank[nm] {
                rank[nm] = max(k["score"] as! CGFloat, s)
            } else {
                rank[nm] = (k["score"] as! CGFloat)
            }
        }
    }
    
    func getRank() -> [Dictionary<String, Any>] {
        var r : [Dictionary<String, Any>] = []
        for (k, v) in rank {
            r.append(["name": k, "score": v])
        }
        r.sort(by: {$0["score"] as! CGFloat > $1["score"] as! CGFloat})
        return r
    }
    
    func save() {
        NSKeyedArchiver.archiveRootObject(self, toFile: PersistentLeaderboard.ArchiveURL.path)
    }
}
