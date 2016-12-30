//
//  Artist.swift
//  Toyboat
//
//  Created by Jack O'Neill on 7/16/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import Foundation

enum State {
    case Collapsed
    case Expanded
}

/**
 Enum to define the number of cell expanded at time
 
 - One:     One cell expanded at time.
 - Several: Several cells expanded at time.
 */
enum NumberOfCellExpanded {
    case One
    case Several
}



struct Artist {
    var name: String
    var songs: [Song]
    var state: State
}
