//
//  Playlist.swift
//  Toyboat
//
//  Created by Jack O'Neill on 7/4/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import Foundation
import RealmSwift

class Playlist: Object
{
    static let sharedInstance = Playlist()
    var list = List<Song>()
    //var list = [Song]()
    dynamic var currIndex : Int = 0
    dynamic var title: String = ""
    
    
    /* Overload subscript operator such that it applies to a circular list */
//    subscript(song: Int) -> Song {
//        get {
//            guard song < self.list.count else
//            {
//                var s = song
//                while s < self.list.count
//                {
//                    s -= self.list.count
//                }
//                return self[s]
//            }
//            return self[song]
//        }
//        
//        set {
//            guard song < self.list.count else
//            {
//                var s = song
//                while s < self.list.count
//                {
//                    s -= self.list.count
//                }
//                self[s] = newValue
//                return
//            }
//            self[song] = newValue
//        }
//    }
    
    /**
     Returns the next song object in the playlist. If the current song is the last object in the playlist, the first song in the playlist is returned.
     */
    
    func next() -> Song
    {
        
        guard currIndex != (self.list.endIndex - 1) else
        {
            self.currIndex = 0
            return self.list[0]
        }
        currIndex += 1
        
        
        return self.list[currIndex]
    }
    
    func currSong() -> Song
    {
        return list[currIndex] 
    }
    
    /**
     Returns the previous song object in the playlist. If the current song is the first object in the playlist, the last song in the playlist is returned.
     */
    
    func prev() -> Song {
        guard currIndex != 0 else
        {
            self.currIndex = (self.list.endIndex - 1)
            return self.list.last!
        }
        currIndex -= 1
        
        return self.list[currIndex]
    }
    
    /**
     Generates a random playlist
     */
    
    func genRandom(first: Song, all: List<Song>)
    {
        var rand = Array(all)
        rand.shuffleInPlace()
        rand.insert(first, atIndex: 0)
        self.list = List(rand)
        self.currIndex = 0
    }
    
    func genInOrder(first: Song, all: List<Song>)
    {
        self.list = all
        self.list.insert(first, atIndex: 0)
    }
    
}



extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}