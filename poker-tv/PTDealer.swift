//
//  PTDealer.swift
//  poker-tv
//
//  Created by Davis Gossage on 4/4/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit

enum BET_OPTIONS: String {
    case CHECK = "CHECK"
    case BET = "BET"
    case FOLD = "FOLD"
    case RAISE = "RAISE"
    case ALLIN = "ALLIN"
}

class PTDealer: NSObject {
    var deck: [PTCard]! = []
    
    var betAmount: Int = 10
    var raiseAmount: Int = 20
    
    var currentBet: Int = 0
    
    override init() {
        super.init()
        shuffleNewDeck()
    }
    
    func dealPlayers(players: [PTPlayer]){
        for player in players{
            player.gameStatus = GAME_STATUS.STATUS_INHAND
            if players.first == player{
                var options: [BET_OPTIONS] = []
                if (betAmount == 0){
                    options.append(.CHECK)
                }
                options.append(.RAISE)
                options.append(.ALLIN)
                options.append(.FOLD)
                player.betOptions = options
            }
            player.hand = [deck.popLast()!,deck.popLast()!]
        }
    }
    
    private func shuffleNewDeck(){
        self.deck = []
        var card = 0
        while card != Rank.__EXHAUST.rawValue {
            self.deck.append(PTCard(suit: Suit.Hearts, rank: Rank(rawValue: card)!))
            self.deck.append(PTCard(suit: Suit.Diamonds, rank: Rank(rawValue: card)!))
            self.deck.append(PTCard(suit: Suit.Spades, rank: Rank(rawValue: card)!))
            self.deck.append(PTCard(suit: Suit.Clubs, rank: Rank(rawValue: card)!))
            card += 1
        }
        self.deck.shuffle()
    }
}

//http://stackoverflow.com/questions/24026510/how-do-i-shuffle-an-array-in-swift
extension Array {
    mutating func shuffle() {
        if count < 2 { return }
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}
