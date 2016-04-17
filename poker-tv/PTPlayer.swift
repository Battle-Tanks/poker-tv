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
    
    var freezeUpdates: Bool = false {
        didSet{
            if (!freezeUpdates){
                PTPubNubCenter.sharedInstance.syncPlayer(self)
            }
        }
    }
    var chips : Int {
        didSet{
            PTPubNubCenter.sharedInstance.updateChips(self)
            if (!freezeUpdates){
                PTPubNubCenter.sharedInstance.syncPlayer(self)
            }
        }
    }
    var state : [String: AnyObject] = [:]
    var gameStatus : GAME_STATUS? {
        didSet{
            PTPubNubCenter.sharedInstance.updateGameStatus(self)
            if (!freezeUpdates){
                PTPubNubCenter.sharedInstance.syncPlayer(self)
            }
        }
    }
    var hand : [PTCard] {
        didSet{
            PTPubNubCenter.sharedInstance.updateHand(self)
            if (!freezeUpdates){
                PTPubNubCenter.sharedInstance.syncPlayer(self)
            }
        }
    }
    var betOptions : (actions: [BET_OPTIONS], raiseAmount: Int, betAmount: Int, callAmount: Int)  {
        didSet{
            PTPubNubCenter.sharedInstance.updateBetOptions(self)
            if (!freezeUpdates){
                PTPubNubCenter.sharedInstance.syncPlayer(self)
            }
        }
    }
    var currentBet: Int?
    var isDealer: Bool = false
    
    class func parseClassName() -> String {
        return "Player"
    }
    
    override init() {
        chips = INITIAL_CHIPS
        hand = []
        betOptions = ([], 0, 0, 0)
        super.init()
        PTPubNubCenter.sharedInstance.updateChips(self)
    }
    
    func clearBetOptions() {
        betOptions = ([], 0, 0, 0)
    }
    
    override var hash: Int{
        return self.objectId!.hash
    }
    
}
