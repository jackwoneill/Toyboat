//
//  PlayerViewController.swift
//  Toyboat
//
//  Created by Jack O'Neill on 7/18/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//
//TODO: REDUNDANT METHODS, CONSOLIDATE

import Foundation
import UIKit
import RealmSwift


class PlayerViewController: UIViewController {
    static let sharedInstance = PlayerViewController()

    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var coverArtImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!

    override func viewDidLoad() {
//        guard Playlist.sharedInstance.currIndex != 0 else
//        {
//            return
//        }
        let song = Playlist.sharedInstance.currSong()
        titleLabel.text = song.title
        artistLabel.text = song.artist
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject! = paths[0]
        let userDir: NSURL! = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("a@a.com"))
        
        let pathToArtwork = userDir.URLByAppendingPathComponent(song.artworkUrl)
        
        // check if it exists before downloading it
        if NSFileManager().fileExistsAtPath(pathToArtwork.path!) {
            if let data = NSData(contentsOfFile: pathToArtwork.path!)
            {
                self.coverArtImageView.image = UIImage(data: data)
            }
            
        }
        
        //else grab image from server /public/a/song.artworkUrl
    }
    
    @IBAction func playPause(sender: UIButton)
    {
        if Player.sharedInstance.paused == true
        {
            Player.sharedInstance.play()
            pauseButton.setTitle("Pause", forState: UIControlState.Normal)
        }
        else
        {
            Player.sharedInstance.pause()
            pauseButton.setTitle("Play", forState: UIControlState.Normal)
        }
        
    }
    
    @IBAction func playNext(sender: UIButton)
    {
        Player.sharedInstance.playNext()
        self.titleLabel.text = Playlist.sharedInstance.currSong().title
        self.artistLabel.text = Playlist.sharedInstance.currSong().artist
        pauseButton.setTitle("Pause", forState: UIControlState.Normal)
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject! = paths[0]
        let userDir: NSURL! = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("a@a.com"))
        
        let pathToArtwork = userDir.URLByAppendingPathComponent(Playlist.sharedInstance.currSong().artworkUrl)
        
        // check if it exists before downloading it
        if NSFileManager().fileExistsAtPath(pathToArtwork.path!) {
            if let data = NSData(contentsOfFile: pathToArtwork.path!)
            {
                self.coverArtImageView.image = UIImage(data: data)
            }
            
        }
        
        //else grab image from server /public/a/song.artworkUrl

    }
    
    //REDUNDANT, CONSOLIDATE playNext() AND playPrev() INTO ONE
    @IBAction func playPrev(sender: UIButton)
    {
        Player.sharedInstance.playPrev()
        self.titleLabel.text = Playlist.sharedInstance.currSong().title
        self.artistLabel.text = Playlist.sharedInstance.currSong().artist
        pauseButton.setTitle("Pause", forState: UIControlState.Normal)
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject! = paths[0]
        let userDir: NSURL! = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("a@a.com"))
        
        let pathToArtwork = userDir.URLByAppendingPathComponent(Playlist.sharedInstance.currSong().artworkUrl)
        
        // check if it exists before downloading it
        if NSFileManager().fileExistsAtPath(pathToArtwork.path!) {
            if let data = NSData(contentsOfFile: pathToArtwork.path!)
            {
                self.coverArtImageView.image = UIImage(data: data)
            }
            
        }
        
        //else grab image from server /public/a/song.artworkUrl
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
