//
//  PTHoldemDealer.swift
//  poker-tv
//
//  Created by Davis Gossage on 4/5/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit

class PTHoldemDealer: PTDealer {
    
    var tableCards: [PTCard] = []
    
    var potAmount: Int = 0
    
    override init() {
        super.init()
    }
    
    func dealRound() -> [PTCard]{
        let rangeToDeal = tableCards.count == 0 ? 0..<3 : 0..<1

        let cardsToDeal = self.deck[rangeToDeal]
        tableCards.appendContentsOf(cardsToDeal)
        self.deck.removeRange(rangeToDeal)
        return Array(cardsToDeal)
    }
}
