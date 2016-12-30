//
//  Song.swift
//  TB
//
//  Created by Jack O'Neill on 6/22/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import RealmSwift
import Foundation

// Song model
class Song: Object {
    dynamic var id = 0
    dynamic var title = ""
    dynamic var artist = ""
    dynamic var artworkUrl = ""
    dynamic var audioUrl: String!
    dynamic var downloaded = false
    dynamic var mpItem = false
    
    //IF DOWNLOADED, CHANGE AUDIOURL TO LOCAL PATH, ELSE GRAB LAST PATH COMPONENT AND APPEND TO HOSTED URL

    override class func primaryKey() -> String? {
        return "audioUrl"
    }
    
    func getArtwork()
    {
        if(!self.artworkUrl.isEmpty)
        {
        
            if let artworkUrl = NSURL(string: "http://localhost:3000/a/\(self.artworkUrl)")
            {
                
                /* CLEAN THIS UP */
                let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                let documentsDirectory: AnyObject = paths[0]
                
                /*CHANGE THE FILE PATH HERE*/
                let userDir = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("a@a.com"))
                /* END CLEANUP */
                
                // your destination file url
                let destinationUrl = userDir.URLByAppendingPathComponent(artworkUrl.lastPathComponent!)
                // check if it exists before downloading it
                if NSFileManager().fileExistsAtPath(destinationUrl.path!) {
                    //realm.beginWrite()
                    
                    print("The file already exists at path")
                } else {
                    if let myAudioDataFromUrl = NSData(contentsOfURL: artworkUrl){
                        // after downloading your data you need to save it to your destination url
                        if myAudioDataFromUrl.writeToURL(destinationUrl, atomically: true) {
                            print("file saved")
                            self.artworkUrl = destinationUrl.path!
                            
                        } else {
                            print("error saving file")
                        }
                    }
                
                }
            }
        }
    }
    
    func download() -> Bool
    {
        
        if let audioUrl = NSURL(string: "http://localhost:3000/directories/a162ece85e7b1b03128f138dfc63a036196c07b6c7e9ea54/\(self.audioUrl)") {
            
            let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let documentsDirectory: AnyObject = paths[0]
            
            let userDir = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("a@a.com"))
            
            let destinationUrl = userDir.URLByAppendingPathComponent(audioUrl.lastPathComponent!)
            print(destinationUrl)
            // check if it exists before downloading it
            if NSFileManager().fileExistsAtPath(destinationUrl.path!) {
                print("The file already exists at path")
            } else {
                if let myAudioDataFromUrl = NSData(contentsOfURL: audioUrl){
                    if myAudioDataFromUrl.writeToURL(destinationUrl, atomically: true) {
                        print("file saved")
                        print(NSURL(string: self.audioUrl)?.lastPathComponent)
                    } else {
                        print("error saving file")
                    }
                }
            }
        }
        
        return true
    }
    
    func unload()
    {
        //perform simple delete
    }
}

