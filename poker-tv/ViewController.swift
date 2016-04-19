//
//  ViewController.swift
//  poker-tv
//
//  Created by Davis Gossage on 4/4/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, PTGameCenterDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var joinGameText: UILabel!
    
    @IBOutlet var card1: UIImageView!
    @IBOutlet var card2: UIImageView!
    @IBOutlet var card3: UIImageView!
    @IBOutlet var card4: UIImageView!
    @IBOutlet var card5: UIImageView!
    
    @IBOutlet var counterLabel: UILabel!
    @IBOutlet var potLabel: UILabel!
    @IBOutlet var sidePotLabel: UILabel!

    @IBOutlet var splashView: UIVisualEffectView!
    
    var cardsShown = 0
    
    let joinGameBaseText = "Join Game at poker-tv.xyz with Code: "
    let gameCenter = PTGameCenter.sharedInstance
    
    var activeCell: PlayerCollectionViewCell?

    override func viewDidLoad() {
        counterLabel.text = ""
        super.viewDidLoad()
        gameCenter.delegate = self
        gameCenter.createGame { (game) in
            self.joinGameText.text = self.joinGameBaseText + game.readableId
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playHoldem(){
        splashView.hidden = true
    }
    
    //MARK: Collection View Data Source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameCenter.dealer.players.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("playerCell", forIndexPath: indexPath) as! PlayerCollectionViewCell
        let player = gameCenter.dealer.players[indexPath.row]
        
        cell.setChipCount(player.chips)
        cell.setName(player.name)
        cell.showDealerButton(player.isDealer)
        
        cell.setBetAmount(player.currentBet)
        
        if (player == gameCenter.dealer.actingPlayer){
            cell.setActive(false)
        }
        else{
            cell.setInactive(false)
        }
        
        cell.cardsAreVisible(player.gameStatus == .STATUS_INHAND)
        
        return cell
    }
    
    
    //MARK: PTGameCenterDelegate
    
    func playerAdded(player: PTPlayer) {
        collectionView.reloadData()
    }
    
    func playerHasAction(player: PTPlayer) {
        collectionView.reloadData()
    }
    
    func playerDidAct() {
        collectionView.reloadData()
        potDidChange()
    }
    
    func timingEvent(isPredeal: Bool, timeLeft: Int) {
        if (isPredeal){
            counterLabel.text = "Dealing in " + String(timeLeft)
        }
        else{
            counterLabel.text = gameCenter.dealer.actingPlayer!.name + " has " + String(timeLeft) + " seconds to act"
        }
    }
    
    func updateMessaging(message: String) {
        counterLabel.text = message
    }
    
    func newGame() {
        cardsShown = 0
        for cell in collectionView.visibleCells() as! [PlayerCollectionViewCell]{
            cell.hideCards()
        }
        potDidChange()
    }
    
    func showCardsForPlayers(players: [PTPlayer]) {
        for player in players{
            let index = gameCenter.dealer.players.indexOf(player)
            let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: index!, inSection: 0)) as! PlayerCollectionViewCell
            cell.showCards(player.hand)
        }
    }
    
    func potDidChange() {
        //if (gameCenter.dealer.pots.count > 0){
            potLabel.text = "Pot: \(gameCenter.dealer.mainPot.potAmount()) Chips"
        //}
        /*if (gameCenter.dealer.pots.count > 1){
            sidePotLabel.text = "Side Pot: \(gameCenter.dealer.mainPot.potAmount()) Chips"
            sidePotLabel.hidden = false
        }
        else{
            sidePotLabel.hidden = true
        }*/
    }
    
    func tableCardsDidChange() {
        let cards = gameCenter.dealer.tableCards
        let cardImages = [card1,card2,card3,card4,card5]
        if (cards.isEmpty){
            for cardImage in cardImages{
                cardImage.image = UIImage(named: "back")
            }
        }
        for i in cardsShown ..< cards.count{
            UIView.animateWithDuration(0.5, animations: {
                cardImages[i].layer.transform = CATransform3DMakeRotation(CGFloat(M_PI_2), 0, 1.0, 0)
            }, completion: { (_) in
                cardImages[i].image = UIImage(named: cards[i].imageString())
                UIView.animateWithDuration(0.5, animations: {
                    cardImages[i].layer.transform = CATransform3DIdentity
                })
            })
        }
        cardsShown = cards.count
    }


}

