//
//  PlayerViewController.swift
//  Toyboat
//
//  Created by Jack O'Neill on 7/18/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift


class PlayerViewController: UIViewController {
    static let sharedInstance = PlayerViewController()


    @IBOutlet weak var coverArtImageView: UIImageView!
    
    @IBOutlet weak var touchButton: UIButton!
    var expanded = false
    

    
    override func viewDidLoad() {
        guard Playlist.sharedInstance.currIndex != 0 else
        {
            return
        }
        //print(Playlist.sharedInstance.currSong().title)
        var song = Playlist.sharedInstance.currSong()
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject! = paths[0]
        let userDir: NSURL! = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("a@a.com"))
        
        let pathToArtwork = userDir.URLByAppendingPathComponent(song.artworkUrl)

        
        // check if it exists before downloading it
        if NSFileManager().fileExistsAtPath(pathToArtwork.path!) {
            if let data = NSData(contentsOfFile: pathToArtwork.path!)
            {
                    // 5
                    self.coverArtImageView.image = UIImage(data: data)
            }
            
        }
        
        //coverArtImageView.image = Playlist.sharedInstance.currSong().artworkUrl
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didTouch(sender: AnyObject) {
        self.view.frame.size.height = UIScreen.mainScreen().bounds.height
        self.view.frame.size.width = UIScreen.mainScreen().bounds.width
        
        NSNotificationCenter.defaultCenter().postNotificationName("expand_player", object: nil)
        
        PlayerViewController.sharedInstance.expanded = !PlayerViewController.sharedInstance.expanded
        
        
        
    }
}
