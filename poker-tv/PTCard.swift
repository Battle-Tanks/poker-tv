//
//  PTCard.swift
//  poker-tv
//
//  Created by Davis Gossage on 4/4/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit

enum Suit: String{
    case Clubs = "Clubs"
    case Diamonds = "Diamonds"
    case Spades = "Spades"
    case Hearts = "Hearts"
}

enum Rank: Int{
    case Two = 0, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace, __EXHAUST
}

class PTCard: NSObject {
    
    let suit: Suit!
    let rank: Rank!
    
    init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
    }
    
    func toEvalString() -> String{
        return cardVal(false) + suit.rawValue
    }
    
    func imageString() -> String{
        return cardVal(true) + "_of_" + suit.rawValue.lowercaseString
    }
    
    private func cardVal(fullName: Bool) -> String{
        //need to match the Evaluator.swift values, so our 0 becomes "2"... 12 becomes "A"
        var value = String(rank.rawValue + 2)
        if (rank.rawValue > 7){
            switch rank.rawValue {
            case 8:
                value = fullName ? "10" : "T"
            case 9:
                value = fullName ? "jack" : "J"
            case 10:
                value = fullName ? "queen" : "Q"
            case 11:
                value = fullName ? "king" : "K"
            case 12:
                value = fullName ? "ace" : "A"
            default:
                print("Invalid card.")
            }
        }
        return value
    }
}
