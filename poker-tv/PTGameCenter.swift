//
//  PTGameCenter.swift
//  poker-tv
//
//  Created by Davis Gossage on 4/4/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit
import Parse

protocol PTGameCenterDelegate {
    func playerAdded(player: PTPlayer)
}

class PTGameCenter: NSObject, PTPubNubDelegate {
    let MAX_PLAYERS = 12
    
    let PLAYERS_TO_START = 2
    
    static let sharedInstance = PTGameCenter()
    var delegate: PTGameCenterDelegate?
    
    var pubnubCenter: PTPubNubCenter! = PTPubNubCenter()
    var activeGame: PTGame?
    
    var players: [PTPlayer] = []
    
    var waitingPlayers: [PTPlayer] = []
    
    var dealer: PTHoldemDealer
    
    override init() {
        dealer = PTHoldemDealer()
        super.init()
        //initialize parse
        Parse.setApplicationId("2MBFKOLhG48cWHDkvPK6cxMYOIAOnzQEUTDIxiJf", clientKey: "OJJSIsZ6uTgqdJKNRIeYHAKrSNJAjtiW5uWARd3F")
        
        //register subclasses
        PTGame.registerSubclass()
        PTPlayer.registerSubclass()
        
        pubnubCenter = PTPubNubCenter.sharedInstance
        pubnubCenter?.delegate = self
    }
    
    /**
     Creates a new game with Parse, and returns the game object
     
     - returns: Game object
     */
    func createGame(completion: (game : PTGame) -> Void){
        callFunction("createGame", parameters: nil) { (response : AnyObject) in
            let game = response as! PTGame
            self.activeGame = game
            self.pubnubCenter?.subscribeToChannel(game.channelName)
            completion(game: game)
        }
    }
    
    /**
     Generic cloud function caller.
     */
    func callFunction(function : String, parameters : [NSObject : AnyObject]?, completion: (result : AnyObject) -> Void){
        PFCloud.callFunctionInBackground(function, withParameters: parameters) { (object : AnyObject?, error : NSError?) -> Void in
            if (error != nil){
                print(error)
            }
            else{
                completion(result : object!)
            }
        }
    }
    
    //MARK: pubnub delegate
    
    func userStateUpdate(username: String, uuid: String, state: [String: AnyObject]) {
        let playerIds = self.players.map { player in
            return player.objectId!
        }
        if (!playerIds.contains(uuid)){
            let query = PFQuery(className: "Player")
            query.getObjectInBackgroundWithId(uuid) { (object: PFObject?, error: NSError?) in
                if (error == nil){
                    let player = object as! PTPlayer
                    if (self.players.count < self.MAX_PLAYERS){
                        self.players.append(player)
                        self.delegate?.playerAdded(player)
                        player.gameStatus = GAME_STATUS.STATUS_INGAME
                    }
                    else{
                        self.waitingPlayers.append(player)
                        player.gameStatus = GAME_STATUS.STATUS_WAITING
                    }
                    if (self.PLAYERS_TO_START == self.players.count){
                        //TODO: start 10 seconds after last player joins
                        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)))
                        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                            self.dealer.dealPlayers(self.players)
                        })
                    }
                }
                else{
                    //TODO: error handling
                }
            }
        }
        else{
            let player = self.players[playerIds.indexOf(uuid)!]
            player.state = state
        }
    }
}
