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
    
    let joinGameBaseText = "Join Game with Code: "
    let gameCenter = PTGameCenter.sharedInstance

    override func viewDidLoad() {
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
    
    //MARK: Collection View Data Source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameCenter.players.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("playerCell", forIndexPath: indexPath) as! PlayerCollectionViewCell
        let player = gameCenter.players[indexPath.row]
        
        cell.setChipCount(player.chips)
        cell.setName(player.name)
        
        return cell
    }
    
    
    //MARK: PTGameCenterDelegate
    
    func playerAdded(player: PTPlayer) {
        collectionView.reloadData()
    }


}

