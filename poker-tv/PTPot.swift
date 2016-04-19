//
//  PTPot.swift
//  poker-tv
//
//  Created by Davis Gossage on 4/9/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit

class PTPot: NSObject {
    var amount: Int = 0
    private var playerStakes: [PTPlayer: Int] = [:]
    
    private var sidePot: PTPot?
    
    private var limitingAmount: Int = Int.max
    
    func potAmount() -> Int{
        return amount
    }
    
    func makeBet(amount: Int, player: PTPlayer){
        if (playerStakes[player] != nil){
            playerStakes[player]! += amount
        }
        else{
            playerStakes[player] = amount
        }
        self.amount += amount
        if (playerStakes[player] > limitingAmount){
            let diff = playerStakes[player]! - limitingAmount
            self.amount -= diff
            sidePot?.makeBet(diff, player: player)
        }
        if (player.chips == 0){
            //this triggers a side pot situation
            if (self.sidePot == nil){
                self.sidePot = PTPot()
            }
            if (playerStakes[player] < limitingAmount){
                for playerStake in playerStakes{
                    limitingAmount = playerStakes[player]!
                    let playerToMove = playerStake.0
                    if (playerToMove != player){
                        let amount = playerStake.1
                        let extraAmount = amount - limitingAmount
                        playerStakes[player] = limitingAmount
                        self.amount -= extraAmount
                        self.sidePot!.makeBet(extraAmount, player: playerToMove)
                    }
                }
            }
        }
    }
    
    func fold(player: PTPlayer){
        playerStakes.removeValueForKey(player)
    }
}
