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
    func userAddedToChannel(username : String, uuid : String)
    func playerMovementEvent(playerId: String, direction: String)
}

class PTPubNubCenter: NSObject, PNObjectEventListener {
    var delegate : PTPubNubDelegate?
    
    static let sharedInstance = PTPubNubCenter()
    
    var client : PubNub?
    
    override init(){
        super.init()
        
        let configuration = PNConfiguration(publishKey: PubNubKey.publish_key, subscribeKey: PubNubKey.subscribe_key)
        client = PubNub.clientWithConfiguration(configuration)
        client?.addListener(self)
    }
    
    
    //MARK: channels
    
    func subscribeToChannel(channelId : String){
        client?.subscribeToChannels([channelId], withPresence: true)
        /*
        channel.bind("pusher_internal:member_added") { (member : AnyObject?) -> Void in
            let memberObj = PresenceChannelMember(userId: member!.valueForKey("user_id") as! String, userInfo: member!.valueForKey("user_info"))
            self.memberAddedToChannel(memberObj)
        }
        channel.bind("pusher:subscription_succeeded") { (member : AnyObject?) -> Void in
            print("!")
        }
        channel.bind("pusher:subscription_error") { (member : AnyObject?) -> Void in
            print("!!")
        }
        channel.bind("client-movement-event", callback: clientMovementEvent)*/
    }
    
    func client(client: PubNub, didReceiveMessage message: PNMessageResult) {
        // Handle new message stored in message.data.message
        if message.data.actualChannel != nil {
            
            // Message has been received on channel group stored in
            // message.data.subscribedChannel
        }
        else {
            
            // Message has been received on channel stored in
            // message.data.subscribedChannel
        }
        
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
                self.delegate?.userAddedToChannel(username, uuid: event.data.presence.uuid!)
            }
        }
        else {
            let state = event.data.presence.state!
            let direction = state["direction"] as! String
            delegate?.playerMovementEvent(event.data.presence.uuid!, direction: direction)
        }
    }
    /*
    func memberAddedToChannel(member : PresenceChannelMember) {
        delegate?.userAddedToChannel(member.userId)
    }*/
    
    func clientMovementEvent(data : AnyObject?) {
        let dataDict = data as! Dictionary<String, String>
        let movementDirection = dataDict["message"]
        print(movementDirection)
        let clientId = dataDict["client"]
        delegate?.playerMovementEvent(clientId!, direction: movementDirection!)
    }
    
}
