//
//  BTPlayer.swift
//  memoryPyramidTV
//
//  Created by Davis Gossage on 1/31/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit
import Parse
import SpriteKit

enum GAME_STATUS: String {
    case STATUS_INGAME = "INGAME"
    case STATUS_INHAND = "INHAND"
    case STATUS_WAITING = "WAITING"
}

class PTPlayer: PFObject, PFSubclassing {
    
    let INITIAL_CHIPS = 200
    
    @NSManaged var name : String
    @NSManaged var socket_id : String
    @NSManaged var game : PTGame
    
    var chips : Int {
        didSet{
            PTPubNubCenter.sharedInstance.updateChips(self)
        }
    }
    var state : [String: AnyObject] = [:]
    var gameStatus : GAME_STATUS? {
        didSet{
            PTPubNubCenter.sharedInstance.updateGameStatus(self)
        }
    }
    var hand : [PTCard] {
        didSet{
            PTPubNubCenter.sharedInstance.updateHand(self)
        }
    }
    var betOptions : [BET_OPTIONS] {
        didSet{
            PTPubNubCenter.sharedInstance.updateBetOptions(self)
        }
    }
    
    class func parseClassName() -> String {
        return "Player"
    }
    
    override init() {
        chips = INITIAL_CHIPS
        hand = []
        betOptions = []
        super.init()
        PTPubNubCenter.sharedInstance.updateChips(self)
    }
    
}
