//
//  PTDealer.swift
//  poker-tv
//
//  Created by Davis Gossage on 4/4/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit

enum BET_ROUNDS {
    case PREFLOP
    case FLOP
    case TURN
    case RIVER
}

enum BET_OPTIONS: String {
    case CHECK = "CHECK"
    case BET = "BET"
    case FOLD = "FOLD"
    case RAISE = "RAISE"
    case ALLIN = "ALLIN"
    case CALL = "CALL"
}

class PTDealer: NSObject {
    
    let MAX_PLAYERS = 12
    
    let TIME_TO_START = 4.0
    let TIME_TO_ACT = 30.0
    
    var deck: [PTCard]! = []
    
    var betAmount: Int = 10
    var raiseAmount: Int = 10
    
    var currentBet: Int = 0
    
    var betRound: BET_ROUNDS?
    
    var tableCards: [PTCard] = [] {
        didSet{
            PTGameCenter.sharedInstance.delegate?.tableCardsDidChange()
        }
    }
    
    var inHand: Bool = false
    var targetTime: NSDate?
    
    var players: [PTPlayer] = [] {
        didSet{
            if (!inHand && players.count > 1){
                targetTime = NSDate(timeIntervalSinceNow: TIME_TO_START)
            }
        }
    }
    var actingPlayer: PTPlayer?
    
    var mainPot: PTPot
    
    override init() {
        mainPot = PTPot()
        super.init()
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(self.gameTimer), userInfo: nil, repeats: true)
    }
    
    func gameTimer(){
        
        let timeDifference = targetTime?.timeIntervalSinceDate(NSDate())
        
        if (!inHand && timeDifference != nil){
            if (timeDifference > 0){
                PTGameCenter.sharedInstance.delegate?.timingEvent(true, timeLeft: Int(timeDifference!))
            }
            else{
                targetTime = nil
                inHand = true
                dealPlayers(playersInGame())
            }
        }
        else if (timeDifference != nil){
            if (timeDifference > 0){
                PTGameCenter.sharedInstance.delegate?.timingEvent(false, timeLeft: Int(timeDifference!))
            }
            else{
                let playerToFold = actingPlayer!
                mainPot.fold(playerToFold)
                if (playersInHand().count == 2){
                    playerToFold.gameStatus = GAME_STATUS.STATUS_INGAME
                    determineWinners(false)
                }
                else{
                    nextPlayerForBetting()
                    playerToFold.gameStatus = GAME_STATUS.STATUS_INGAME
                }
                playerToFold.freezeUpdates = false
            }
        }
    }
    
    func addPlayerToTable(player: PTPlayer){
        self.players.append(player)
        if (self.players.count < self.MAX_PLAYERS){
            player.gameStatus = GAME_STATUS.STATUS_INGAME
        }
        else{
            player.gameStatus = GAME_STATUS.STATUS_WAITING
        }
    }
    
    func dealGame(){
        PTGameCenter.sharedInstance.delegate?.newGame()
        shuffleNewDeck()
        betRound = .PREFLOP
        currentBet = 0
        for player in playersInGameWithNoChips(){
            player.gameStatus = GAME_STATUS.STATUS_WAITING
        }
        while (waitingPlayersWithChips().count > 0 && playersInGame().count < self.MAX_PLAYERS){
            waitingPlayersWithChips().first?.gameStatus = GAME_STATUS.STATUS_INGAME
        }
        for player in players{
            player.freezeUpdates = true
            player.gameStatus = GAME_STATUS.STATUS_INHAND
            player.currentBet = nil
            player.hand = [deck.popLast()!, deck.popLast()!]
            player.freezeUpdates = false
        }
        let previousDealer = playerWithDealerButton()
        let newDealer = playerAfterDealerButton()
        previousDealer.isDealer = false
        newDealer.isDealer = true
        self.performSelector(#selector(actionToPlayer), withObject: playerAfterDealerButton(), afterDelay: 0.6)
    }
    
    func dealPlayers(players: [PTPlayer]){
        shuffleNewDeck()
        betRound = .PREFLOP
        for player in players{
            if (player.chips > 0){
                player.gameStatus = GAME_STATUS.STATUS_INHAND
                if players.first == player{
                    player.isDealer = true
                }
                player.hand = [deck.popLast()!, deck.popLast()!]
            }
            else{
                player.gameStatus = GAME_STATUS.STATUS_WAITING
            }
        }
        if (playersInHand().count > 1){
            actionToPlayer(playerAfterDealerButton())
        }
    }
    
    func actionToPlayer(player: PTPlayer){
        actingPlayer = player
        PTGameCenter.sharedInstance.delegate?.playerHasAction(player)
        targetTime = NSDate().dateByAddingTimeInterval(TIME_TO_ACT)
        var actions: [BET_OPTIONS] = []
        if (currentBet == 0){
            actions.append(.CHECK)
            actions.append(.BET)
        }
        else{
            actions.append(.CALL)
            if (currentBet + raiseAmount <= player.chips){
                actions.append(.RAISE)
            }
        }
        actions.append(.ALLIN)
        actions.append(.FOLD)
        var callAmount = (player.currentBet != nil) ? currentBet - player.currentBet! : currentBet
        let actualBetAmount = player.chips >= betAmount ? betAmount : player.chips
        if (currentBet > player.chips){
            callAmount = player.chips
        }
        player.betOptions = (actions: actions, raiseAmount: raiseAmount, betAmount: actualBetAmount, callAmount: callAmount)
    }
    
    private func playersInGame() -> [PTPlayer]{
        return playerFilterByStatus(.STATUS_INGAME)
    }
    
    private func playersInGameWithNoChips() -> [PTPlayer]{
        return playersInGame().filter({ (player) -> Bool in
            return player.chips == 0
        })
    }
    
    private func playersInHand() -> [PTPlayer]{
        return playerFilterByStatus(.STATUS_INHAND)
    }
    
    private func waitingPlayersWithChips() -> [PTPlayer]{
        return playerFilterByStatus(.STATUS_WAITING).filter({ (player) -> Bool in
            return player.chips > 0
        })
    }
    
    private func playerFilterByStatus(status: GAME_STATUS) -> [PTPlayer]{
        return players.filter({ (player) -> Bool in
            return player.gameStatus == status
        })
    }
    
    func playerAction(playerId: String, action: BET_OPTIONS, amount: Int){
        actingPlayer?.freezeUpdates = true
        actingPlayer?.clearBetOptions()
        var betAmount = amount
        if (actingPlayer?.objectId == playerId){
            switch action {
            case .CHECK:
                actingPlayer?.currentBet = 0
                mainPot.makeBet(0, player: actingPlayer!)
                break
            case .ALLIN:
                betAmount = actingPlayer!.chips
                fallthrough
            case .BET:
                currentBet = betAmount
                if (actingPlayer?.currentBet != nil){
                    currentBet += actingPlayer!.currentBet!
                }
                fallthrough
            case .CALL:
                actingPlayer!.chips -= amount
                mainPot.makeBet(betAmount, player: actingPlayer!)
                actingPlayer!.currentBet = currentBet
                break
            case .FOLD:
                let playerToFold = actingPlayer!
                mainPot.fold(playerToFold)
                if (playersInHand().count == 2){
                    playerToFold.gameStatus = GAME_STATUS.STATUS_INGAME
                    determineWinners(false)
                }
                else{
                    nextPlayerForBetting()
                    playerToFold.gameStatus = GAME_STATUS.STATUS_INGAME
                }
                playerToFold.freezeUpdates = false
                return
            default:
                break
            }
        }
        actingPlayer?.freezeUpdates = false
        nextPlayerForBetting()
    }
    
    func nextPlayerForBetting(){
        let playersDueToBet = playersInHand().filter { (player) -> Bool in
            if (player.currentBet == nil || player == actingPlayer){
                return true
            }
            return player.currentBet < currentBet && player.chips > 0
        }
        if (playersDueToBet.count == 1){
            self.performSelector(#selector(advanceBettingRound), withObject: nil, afterDelay: 1.0)
        }
        else{
            let indexOfActingPlayer = playersDueToBet.indexOf(actingPlayer!)!
            var indexOfNextPlayerToAct = indexOfActingPlayer + 1
            if (indexOfNextPlayerToAct == playersDueToBet.count){
                indexOfNextPlayerToAct = 0
            }
            actionToPlayer(playersDueToBet[indexOfNextPlayerToAct])
        }
    }
    
    func allInSituation() -> Bool{
        let playersWithChips = playersInHand().filter { (player) -> Bool in
            return player.chips > 0
        }
        return playersWithChips.count <= 1
    }
    
    func advanceBettingRound(){
        currentBet = 0
        switch betRound! {
        case .PREFLOP:
            betRound = .FLOP
            tableCards.appendContentsOf([deck.popLast()!, deck.popLast()!, deck.popLast()!])
        case .FLOP:
            betRound = .TURN
            tableCards.append(deck.popLast()!)
        case .TURN:
            betRound = .RIVER
            tableCards.append(deck.popLast()!)
        case .RIVER:
            determineWinners(true)
            return
        }
        _ = players.map { (player) -> Void in
            player.currentBet = nil
        }
        if (allInSituation()){
            targetTime = nil
            self.performSelector(#selector(advanceBettingRound), withObject: nil, afterDelay: 3.0)
            PTGameCenter.sharedInstance.delegate?.updateMessaging("Players are All-In")
            PTGameCenter.sharedInstance.delegate?.showCardsForPlayers(playersInHand())
        }
        else{
            actionToPlayer(playerAfterDealerButton())
        }
    }
    
    func determineWinners(broadcast: Bool) {
        mainPot.calculateWinners(tableCards)
        playersWin(broadcast)
    }
    
    func playersWin(broadcast: Bool){
        targetTime = nil
        var pot = mainPot
        var message: String = ""
        message += calculateWinnersForPot(broadcast, pot: pot, isSidepot: false)
        while (pot.sidePot != nil){
            pot = pot.sidePot!
            message += calculateWinnersForPot(broadcast, pot: pot, isSidepot: true)
        }
        
        PTGameCenter.sharedInstance.delegate?.updateMessaging(message)
        mainPot = PTPot()
        self.performSelector(#selector(dealGame), withObject: nil, afterDelay: 7.0)
    }
    
    func calculateWinnersForPot(broadcast: Bool, pot: PTPot, isSidepot: Bool) -> String{
        let winningNames = pot.winningPlayers.map { (player) -> String in
            return player.name
        }.joinWithSeparator(", ")
        for player in pot.winningPlayers{
            player.chips += pot.potAmount() / pot.winningPlayers.count
        }
        let sidepotText = isSidepot ? " Sidepot: " : ""
        let winningHandName = pot.winningHand == nil ? "muck" : pot.winningHand!.name.rawValue
        if (broadcast){
            PTGameCenter.sharedInstance.delegate?.showCardsForPlayers(pot.winningPlayers)
            if (pot.winningPlayers.count > 1){
                return "\(sidepotText)\(winningNames) win \(pot.potAmount() / pot.winningPlayers.count) with \(winningHandName)."
            }
            else{
                return "\(sidepotText)\(winningNames) wins \(pot.potAmount()) with \(winningHandName)."
            }
        }
        else{
            return "\(sidepotText)\(winningNames) wins \(pot.potAmount())."
        }
    }
    
    private func playerWithDealerButton() -> PTPlayer{
        let playersWithDealerButton = players.filter { (player) -> Bool in
            return player.isDealer
        }
        return playersWithDealerButton.first!
    }
    
    private func playerAfterDealerButton() -> PTPlayer{
        var dealer: PTPlayer?
        let playersInHandPlusDealer = players.filter { (player) -> Bool in
            if (player.isDealer){
                dealer = player
                return true
            }
            return player.gameStatus == .STATUS_INHAND
        }
        let indexOfDealer = playersInHandPlusDealer.indexOf(dealer!)!
        var indexOfPlayerAfterDealer = indexOfDealer + 1
        if (indexOfPlayerAfterDealer == playersInHandPlusDealer.count){
            indexOfPlayerAfterDealer = 0
        }
        return playersInHandPlusDealer[indexOfPlayerAfterDealer]
    }
    
    private func shuffleNewDeck(){
        tableCards.removeAll()
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
