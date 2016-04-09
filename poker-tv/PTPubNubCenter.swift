//
//  MPPubNubCenter.swift
//  battle-tanks-sprite
//
//  Created by Davis Gossage on 1/31/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit
import PubNub

protocol PTPubNubDelegate {
    func userStateUpdate(username : String, uuid : String, state: [String: AnyObject])
    func playerAction(playerId: String, action: BET_OPTIONS, amount: Int)
}

class PTPubNubCenter: NSObject, PNObjectEventListener {
    var delegate : PTPubNubDelegate?
    
    static let sharedInstance = PTPubNubCenter()
    
    var gameChannel : String?
    var client : PubNub?
    
    override init(){
        super.init()
        
        let configuration = PNConfiguration(publishKey: PubNubKey.publish_key, subscribeKey: PubNubKey.subscribe_key)
        client = PubNub.clientWithConfiguration(configuration)
        client?.addListener(self)
    }
    
    func updateGameStatus(player: PTPlayer){
        player.state["GAME_STATUS"] = player.gameStatus!.rawValue
    }
    
    func updateChips(player: PTPlayer){
        player.state["CHIPS"] = player.chips
    }
    
    func updateHand(player: PTPlayer){
        player.state["HAND"] = player.hand.map({ (card) -> AnyObject in
            return card.imageString()
        })
    }
    
    func updateBetOptions(player: PTPlayer){
        player.state["BET_OPTIONS"] = player.betOptions.actions.map({ (option) -> String in
            return option.rawValue
        })
        player.state["BET_AMOUNT"] = player.betOptions.betAmount
        player.state["RAISE_AMOUNT"] = player.betOptions.raiseAmount
        player.state["CALL_AMOUNT"] = player.betOptions.callAmount
    }
    
    func syncPlayer(player: PTPlayer){
        setUpdatedState(player.state, uuid: player.objectId!)
    }
    
    private func setUpdatedState(state: [String: AnyObject], uuid: String){
        client?.setState(state, forUUID: uuid, onChannel: gameChannel!, withCompletion: nil)
    }
    
    //MARK: channels
    
    func subscribeToChannel(channelId : String){
        gameChannel = channelId
        client?.subscribeToChannels([channelId], withPresence: true)
    }
    
    func client(client: PubNub, didReceiveMessage message: PNMessageResult) {
        //delegate?.playerAction(message.data.message, action: <#T##BET_OPTIONS#>, amount: <#T##Int#>)
        // Handle new message stored in message.data.message
        if message.data.actualChannel != nil {
            
            // Message has been received on channel group stored in
            // message.data.subscribedChannel
        }
        else {
            
            // Message has been received on channel stored in
            // message.data.subscribedChannel
        }
        
        let formattedMessage = message.data.message as! [String: AnyObject]
        
        let betOption = BET_OPTIONS(rawValue: formattedMessage["ACTION"] as! String)
        var actualAmount = 0
        if (formattedMessage["AMOUNT"] != nil){
            actualAmount = formattedMessage["AMOUNT"] as! Int
        }
        delegate?.playerAction(formattedMessage["uuid"] as! String, action: betOption!, amount: actualAmount)
        print("Received message: \(message.data.message) on channel " +
            "\((message.data.actualChannel ?? message.data.subscribedChannel)!) at " +
            "\(message.data.timetoken)")
    }
    
    func client(client: PubNub, didReceiveStatus status: PNStatus) {
        if status.category == .PNUnexpectedDisconnectCategory {
            
            // This event happens when radio / connectivity is lost
        }
        else if status.category == .PNConnectedCategory {
            
            // Connect event. You can do stuff like publish, and know you'll get it.
            // Or just use the connected event to confirm you are subscribed for
            // UI / internal notifications, etc
            
            // Select last object from list of channels and send message to it.
            _ = client.channels().last! as String
        }
        else if status.category == .PNReconnectedCategory {
            
            // Happens as part of our regular operation. This event happens when
            // radio / connectivity is lost, then regained.
        }
        else if status.category == .PNDecryptionErrorCategory {
            
            // Handle messsage decryption error. Probably client configured to
            // encrypt messages and on live data feed it received plain text.
        }
    }
    
    func client(client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        // Handle presence event event.data.presenceEvent (one of: join, leave, timeout,
        // state-change).
        if event.data.actualChannel != nil {
            
            // Presence event has been received on channel group stored in
            // event.data.subscribedChannel
        }
        else {
            
            // Presence event has been received on channel stored in
            // event.data.subscribedChannel
        }
        
        if event.data.presenceEvent != "state-change" {
            //see if this event is us joining or a client joining
            if (event.data.presence.state != nil){
                let state = event.data.presence.state!
                let username = state["username"] as! String
                self.delegate?.userStateUpdate(username, uuid: event.data.presence.uuid!, state: state)
            }
        }
        else {
            
        }
    }
    /*
    func memberAddedToChannel(member : PresenceChannelMember) {
        delegate?.userAddedToChannel(member.userId)
    }*/
}
