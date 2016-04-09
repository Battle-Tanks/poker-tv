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
    
    let TIME_TO_START = 10.0
    let TIME_TO_ACT = 60.0
    
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
    
    var pots: [PTPot] = [PTPot()]
    var mainPot: PTPot
    
    var evaluator = Evaluator()
    
    override init() {
        mainPot = pots[0]
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
                actingPlayer!.gameStatus = GAME_STATUS.STATUS_INGAME
                nextPlayerForBetting()
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
        shuffleNewDeck()
        betRound = .PREFLOP
        currentBet = 0
        for player in players{
            player.freezeUpdates = true
            player.gameStatus = GAME_STATUS.STATUS_INHAND
            player.currentBet = nil
            player.hand = [deck.popLast()!, deck.popLast()!]
            player.freezeUpdates = false
        }
        PTGameCenter.sharedInstance.delegate?.newGame()
        let previousDealer = playerWithDealerButton()
        let newDealer = playerAfterDealerButton()
        previousDealer.isDealer = false
        newDealer.isDealer = true
        actionToPlayer(playerAfterDealerButton())
    }
    
    func dealPlayers(players: [PTPlayer]){
        shuffleNewDeck()
        betRound = .PREFLOP
        for player in players{
            player.gameStatus = GAME_STATUS.STATUS_INHAND
            if players.first == player{
                player.isDealer = true
            }
            player.hand = [deck.popLast()!, deck.popLast()!]
        }
        actionToPlayer(playerAfterDealerButton())
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
        if (currentBet > player.chips){
            callAmount = player.chips
        }
        player.betOptions = (actions: actions, raiseAmount: raiseAmount, betAmount: betAmount, callAmount: callAmount)
    }
    
    private func playersInGame() -> [PTPlayer]{
        return playerFilterByStatus(.STATUS_INGAME)
    }
    
    private func playersInHand() -> [PTPlayer]{
        return playerFilterByStatus(.STATUS_INHAND)
    }
    
    private func waitingPlayers() -> [PTPlayer]{
        return playerFilterByStatus(.STATUS_WAITING)
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
                break
            case .ALLIN:
                betAmount = actingPlayer!.chips
                fallthrough
            case .BET:
                //player1: bet 10
                //player2: raise 10 = bet 20
                //player1: raise 10 = bet 30
                currentBet = betAmount
                if (actingPlayer?.currentBet != nil){
                    currentBet += actingPlayer!.currentBet!
                }
                fallthrough
            case .CALL:
                actingPlayer!.chips -= betAmount
                mainPot.amount += betAmount
                actingPlayer!.currentBet = currentBet
                break
            case .FOLD:
                actingPlayer?.gameStatus = GAME_STATUS.STATUS_INGAME
                actingPlayer?.freezeUpdates = false
                if (playersInHand().count == 1){
                    determineWinners(false)
                }
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
            return player.currentBet < currentBet
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
    
    func advanceBettingRound(){
        currentBet = 0
        switch betRound! {
        case .PREFLOP:
            betRound = .FLOP
            for _ in 0 ..< 3{
                tableCards.append(deck.popLast()!)
            }
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
        actionToPlayer(playerAfterDealerButton())
    }
    
    func determineWinners(broadcast: Bool) {
        var winningHand: HandRank?
        var winningPlayers: [PTPlayer] = []
        _ = playersInHand().map { (player) -> Void in
            var tableCardStrings = tableCards.map({ (card) -> String in
                return card.toEvalString()
            })
            tableCardStrings.append(player.hand[0].toEvalString())
            tableCardStrings.append(player.hand[1].toEvalString())
            let handRank = evaluator.evaluate7(tableCardStrings)
            if (handRank.rank == winningHand?.rank){
                winningPlayers.append(player)
            }
            if (winningHand == nil || handRank.rank < winningHand!.rank){
                winningPlayers.removeAll()
                winningPlayers.append(player)
                winningHand = handRank
            }
        }
        targetTime = nil
        var message: String?
        let winningNames = winningPlayers.map { (player) -> String in
            return player.name
        }.joinWithSeparator(", ")
        if (broadcast){
            if (winningPlayers.count > 1){
                message = "\(winningNames) win with \(winningHand!.name.rawValue)"
            }
            else{
                message = "\(winningNames) wins with \(winningHand!.name.rawValue)"
            }
            PTGameCenter.sharedInstance.delegate?.playersWin(winningPlayers)
        }
        else{
            message = "\(winningNames) wins."
        }
        PTGameCenter.sharedInstance.delegate?.updateMessaging(message!)
        for player in winningPlayers{
            player.chips += mainPot.amount / winningPlayers.count
        }
        mainPot.amount = 0
        self.performSelector(#selector(dealGame), withObject: nil, afterDelay: 7.0)
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
