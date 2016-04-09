//
//  PlayerCollectionViewCell.swift
//  poker-tv
//
//  Created by Davis Gossage on 4/5/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit

class PlayerCollectionViewCell: UICollectionViewCell {
    @IBOutlet private var dealerButtonLabel: UIView!
    @IBOutlet private var playerNameLabel: UILabel!
    @IBOutlet private var chipCountLabel: UILabel!
    @IBOutlet private var currentBetLabel: UILabel!
    @IBOutlet private var card1: UIImageView!
    @IBOutlet private var card2: UIImageView!
    
    @IBOutlet private var activePlayerConstraint: NSLayoutConstraint?
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func setBetAmount(amount: Int?){
        if (amount != nil){
            currentBetLabel.hidden = false
            currentBetLabel.text = amount == 0 ? "Check" : "Bet: \(amount!)"
        }
        else{
            currentBetLabel.hidden = true
        }
    }
    
    func showDealerButton(show: Bool){
        dealerButtonLabel.hidden = !show
    }
    
    func setChipCount(count: Int){
        chipCountLabel.text = String(count) + " Chips"
    }
    
    func setName(name: String){
        playerNameLabel.text = name
    }
    
    func showCards(cards: [PTCard]){
        cardsAreVisible(true)
        card1.image = UIImage(named:cards[0].imageString())
        card2.image = UIImage(named:cards[1].imageString())
    }
    
    func hideCards(){
        cardsAreVisible(true)
        card1.image = nil
        card2.image = nil
    }
    
    func cardsAreVisible(visible: Bool){
        card1.hidden = !visible
        card2.hidden = !visible
    }
    
    func setActive(animate: Bool){
        activePlayerConstraint?.constant = 22;
        if (animate){
            UIView.animateWithDuration(0.25) {
                self.layoutIfNeeded()
            }
        }
        else{
            self.layoutIfNeeded()
        }
    }
    
    func setInactive(animate: Bool){
        activePlayerConstraint?.constant = 0;
        if (animate){
            UIView.animateWithDuration(0.25) {
                self.layoutIfNeeded()
            }
        }
        else{
            self.layoutIfNeeded()
        }
    }
}
