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
    
    var sidePot: PTPot?
    
    private var limitingAmount: Int = Int.max
    
    var evaluator = Evaluator()
    
    var winningHand: HandRank?
    var winningPlayers: [PTPlayer] = []
    
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
            playerStakes[player] = limitingAmount
            sidePot?.makeBet(diff, player: player)
        }
        else if (player.chips == 0){
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
                        if (extraAmount > 0){
                            playerStakes[playerToMove] = limitingAmount
                            self.amount -= extraAmount
                            self.sidePot!.makeBet(extraAmount, player: playerToMove)
                        }
                    }
                }
            }
        }
    }
    
    func calculateWinners(tableCards: [PTCard]){
        if (playerStakes.keys.count == 1){
            self.winningPlayers.append(playerStakes.keys.first!)
            return
        }
        for player in playerStakes.keys {
            var tableCardStrings = tableCards.map({ (card) -> String in
                return card.toEvalString()
            })
            tableCardStrings.append(player.hand[0].toEvalString())
            tableCardStrings.append(player.hand[1].toEvalString())
            let handRank = self.evaluator.evaluate7(tableCardStrings)
            if (handRank.rank == self.winningHand?.rank){
                self.winningPlayers.append(player)
            }
            if (self.winningHand == nil || handRank.rank < self.winningHand!.rank){
                self.winningPlayers.removeAll()
                self.winningPlayers.append(player)
                self.winningHand = handRank
            }
        }
        if (self.sidePot != nil){
            self.sidePot?.calculateWinners(tableCards)
        }
    }
    
    func fold(player: PTPlayer){
        playerStakes.removeValueForKey(player)
    }
}
