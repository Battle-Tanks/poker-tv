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
    @IBOutlet private var card1: UIImageView!
    @IBOutlet private var card2: UIImageView!
    
    func setChipCount(count: Int){
        chipCountLabel.text = String(count) + " Chips"
    }
    
    func setName(name: String){
        playerNameLabel.text = name
    }
}
