//
//  GlobalConstants.swift
//  agario
//
//  Created by Yunhan Li on 9/18/15.
//
//
import SpriteKit
struct GlobalConstants {
    
    struct Category {
        static let wall      :UInt32 = 0b0001;
        static let food      :UInt32 = 0b0010;
        static let ball      :UInt32 = 0b0100;
        static let barrier   :UInt32 = 0b1000;
    }
    
    struct ZPosition {
        static let food    :CGFloat = 0
        static let ball    :CGFloat = 10
        static let barrier :CGFloat = 49
        static let wall    :CGFloat = 50000
    }
    
    static let Color = [
        0xF44336, // Red
        0xE91E63, // Pink
        0x9C27B0, // Purple
        0x3F51B5, // DarkBlue
        0x03A9F4, // LightBlue
        0xFFEB3B, // Yellow
        0xFF9800, // Orange
        0x4CAF50, // DarkGreen
        0x8BC34A, // Lime
        0xFF9955, // Peach
    ]
    
    static let Skin = [
        "china": "china",
        "united kingdom" : "uk",
        "usa"            : "usa",
        "australia"      : "australia",
        "german"         : "german",
        "canada"         : "canada",
        "india"          : "india",
        "doge"           : "doge"
    ]
	
	static let SkinName = [
		"china",
		"united kingdom",
		"usa",
		"australia",
		"german",
		"canada",
		"india",
		"doge"
	]
    
    static let FoodRadius = CGFloat(10)
    static let BarrierRadius = CGFloat(70)
    static let MapSize = CGSize(width: 6000, height: 6000)	// 4000 * 4000
    static let FoodLimit = 500								// 500
    static let FoodRespawnRate = 30
    static let BarrierLimit = 5								// 15
    static let BarrierRespawnInterval = 45
    static let LeaderboardUpdateInterval = 1
    static let SoundUpateInterval = 2
    static let minumDecibel = Float(40.0)
    static let PersistentLeaderboardUpdateInterval = 30
    static let MaxNameLength = 10
	static let StupidPlayerCount		= 0
	static let SmarterPlayerCount	= 8
    
    // Server
    static let BroadcastInterval : Double = 0.10
}
