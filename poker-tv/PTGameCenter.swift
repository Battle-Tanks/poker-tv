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
    func playerHasAction(player: PTPlayer)
    func playerDidAct()
    func timingEvent(isPredeal: Bool, timeLeft: Int)
    func updateMessaging(message: String)
    func potDidChange()
    func tableCardsDidChange()
}

class PTGameCenter: NSObject, PTPubNubDelegate {
    
    static let sharedInstance = PTGameCenter()
    var delegate: PTGameCenterDelegate?
    
    var pubnubCenter: PTPubNubCenter! = PTPubNubCenter()
    var activeGame: PTGame?
    
    var dealer: PTDealer
    
    override init() {
        dealer = PTDealer()
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
    
    func playerAction(playerId: String, action: BET_OPTIONS, amount: Int) {
        delegate?.playerDidAct()
        dealer.playerAction(playerId, action: action, amount: amount)
    }
    
    func userStateUpdate(username: String, uuid: String, state: [String: AnyObject]) {
        let playerIds = dealer.players.map { player in
            return player.objectId!
        }
        if (!playerIds.contains(uuid)){
            let query = PFQuery(className: "Player")
            query.getObjectInBackgroundWithId(uuid) { (object: PFObject?, error: NSError?) in
                if (error == nil){
                    let player = object as! PTPlayer
                    self.dealer.addPlayerToTable(player)
                    self.delegate?.playerAdded(player)
                }
                else{
                    //TODO: error handling
                }
            }
        }
        else{
            let player = self.dealer.players[playerIds.indexOf(uuid)!]
            player.state = state
        }
    }
}
