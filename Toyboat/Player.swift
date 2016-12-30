//
//  Player.swift
//  Toyboat
//
//  Created by Jack O'Neill on 7/4/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import Foundation
import AVFoundation

class Player {
    let playlist = Playlist.sharedInstance
    static let sharedInstance = Player()
    static let sharedUrl : NSURL = NSURL(string: "")!
    let session = AVAudioSession.sharedInstance()
    var error: NSError?
    
    var player:AVPlayer = AVPlayer()
    
    init() {
        try! session.setCategory(AVAudioSessionCategoryPlayback)
        try! session.overrideOutputAudioPort(AVAudioSessionPortOverride.None)
        try! session.setActive(true)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(
            self,
            selector: #selector(trackDidFinishPlaying),
            name: "AVPlayerItemDidPlayToEndTimeNotification",
            object: self.player.currentItem
        )
    }
    
    
    func play() {
        self.player.play()
        // Put play code here
    }
    
    func pause() {
        self.player.pause()
    }
    
    func playNext()
    {
        self.playlist.next()
        let song = self.playlist.currSong()
        //self.playWithURL(self.playlist.currSong().audioUrl)
        
        
        /* CONSOLIDATE THIS INTO playWithURL */
        var destinationUrl: NSURL = NSURL(string: "")!
        
        if (song.downloaded == true)
        {
            let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL?
            
            /* CLEAN THIS UP */
            let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let documentsDirectory: AnyObject = paths[0]
            
            /*CHANGE THE FILE PATH HERE*/
            let userDir = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("a@a.com"))
            /* END CLEANUP */
            
            // your destination file url
            destinationUrl = userDir.URLByAppendingPathComponent(song.audioUrl)
        }
        else
        {
            let serverUrl = String("http://localhost:3000/directories/a162ece85e7b1b03128f138dfc63a036196c07b6c7e9ea54/")
            destinationUrl = NSURL(string: [serverUrl,song.audioUrl]
                .flatMap{$0}
                .joinWithSeparator(""))!
            
        }
        
        self.playWithURL(destinationUrl)

    }
    
    
    
    func playWithURL(url : NSURL) {
        let playerItem = AVPlayerItem(URL: url)
        self.player = AVPlayer(playerItem: playerItem)
        //self.player = AVPlayer.init(playerItem: item)
        
        self.player.play()
        
        // Put play code here
    }
    
    @objc func trackDidFinishPlaying(notification: NSNotification)
    {
        self.playNext()
        
    }
    

}