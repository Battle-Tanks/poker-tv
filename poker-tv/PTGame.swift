//
//  BTGame.swift
//  memoryPyramidTV
//
//  Created by Davis Gossage on 1/31/16.
//  Copyright © 2016 Davis Gossage. All rights reserved.
//

import UIKit
import Parse

class PTGame: PFObject, PFSubclassing {
    
    class func parseClassName() -> String {
        return "Game"
    }
    
    @NSManaged var channelName : String
    @NSManaged var readableId : String
    
}
