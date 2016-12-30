//
//  Parent.swift
//  Toyboat
//
//  Created by Jack O'Neill on 7/3/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import Foundation

struct Parent {
    
    var state: State
    
    var childs: [Song]
        
    var title: String
}

func != (lhs: (Int, Int), rhs: (Int, Int)) -> Bool {
    return lhs.0 != rhs.0 && rhs.1 != lhs.1
}