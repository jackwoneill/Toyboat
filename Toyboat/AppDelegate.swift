//
//  AppDelegate.swift
//  Toyboat
//
//  Created by Jack O'Neill on 6/20/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import UIKit
import RealmSwift
import MediaPlayer
import CoreImage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarDelegate {
    
    var window: UIWindow?
    
    var creatingPlaylist = false
    var newPlaylistIds = Set<String>()
    var readyToSync = false
    
    @IBOutlet weak var finishPlaylistView: UIView!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 7,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 7) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        if (KeychainWrapper.stringForKey("authToken") == nil)
        {
            //redirect to login
            loginUser("a@a.com", password: "password")
        }
        let realm = try! Realm()
        sync()
        checkLocal()
//        realm.beginWrite()
//        realm.deleteAll()
//        try! realm.commitWrite()
        //loginUser("a@a.com", password: "password")
        //******ADD***** IF NO SONGS IN REALM, ASK TO IMPORT LOCAL
        if realm.objects(Song.self).count == 0
        {
            loadLocal()
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        let userPath = NSURL(fileURLWithPath: documentsDirectory).URLByAppendingPathComponent("a@a.com")
        
        //MAKE THIS A CONDITIONAL -> GUARD FOLDER EXISTS ELSE CREATE
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(userPath.path!, withIntermediateDirectories: true, attributes: nil)
            
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
        
        let fm = NSFileManager.defaultManager()
        
        let path = NSBundle.mainBundle().resourcePath!
        
        do {
            let items = try fm.contentsOfDirectoryAtPath(userPath.path!)
            
            for item in items {
                print("Found \(item)")
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("sync_with_realm", object: nil)
        }
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func loginUser(email:String, password:String)
    {
        let loginString = "user[email]=\(email)&user[password]=\(password)"
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        
        // create the request
        let url = NSURL(string: "http://localhost:3000/api/1/sessions")
        
        let request = NSMutableURLRequest(URL:url!)
        
        request.timeoutInterval = 10
        request.HTTPMethod = "POST"
        request.HTTPBody = loginString.dataUsingEncoding(NSUTF8StringEncoding)
        
        //let request: NSMutableURLRequest = NSMutableURLRequest(URL: url!)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.HTTPMethod = "POST"
        
        let session = NSURLSession.sharedSession()
        
        
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            if let httpResponse = response as? NSHTTPURLResponse {
                let statusCode = httpResponse.statusCode
                
                if (statusCode == 200) {
                    do{
                        
                        print(httpResponse)
                        
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments) as! NSDictionary
                        print(json)
                        
                        let dicResponse = json.valueForKey("response") as! NSDictionary
                        let token = dicResponse.valueForKey("token") as! String
                        
                        print("auth token = : \(token)")
                        
                        let didSave:Bool = KeychainWrapper.setString(token, forKey: "authToken")
                        
                        if !didSave
                        {
                            EXIT_FAILURE
                        }
                        else
                        {
                            self.sync()
                        }
                        
                        //HERE WE ARE LOGGED IN, START REQUEST TO JSON FETCH SONG INFO
                        
                    }catch {
                        print("Error with Json: \(error)")
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName("sync_with_realm", object: nil)
                    }
                    
                }
            }
            
        }
        
        task.resume()
        
    }
    
    func checkLocal()
    {
        //ENSURE FILES IN REALM AND IN LOCAL DB PRIOR
        
        //ALSO CHECK SONGS THAT ARE NO LONGER LOCALLY DOWNLOADED
        
        let realm = try! Realm()
        
        let songs = realm.objects(Song.self).filter("mpItem = true")
        
        let tbMpSet = Set(songs.map({$0.audioUrl}))

        let mediaItems = MPMediaQuery.songsQuery().items

        let filteredSet = mediaItems!.filter { $0.valueForProperty(MPMediaItemPropertyAssetURL) != nil }
        let ipodFilesSet = Set(filteredSet.map {($0.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL).absoluteString })
        
        let notFoundList = tbMpSet.filter( {ipodFilesSet.contains($0) == false } )

        print(notFoundList)
        
        realm.beginWrite()
        for i in notFoundList
        {
            let delSong = realm.objectForPrimaryKey(Song.self, key: i)
            realm.delete(delSong!)
        }
        try! realm.commitWrite()

    }
    
    //ONLY RUN FIRST TIME
    func loadLocal()
    {
        let realm = try! Realm()
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        let userPath = NSURL(fileURLWithPath: documentsDirectory).URLByAppendingPathComponent("a@a.com")
        
        let mediaItems = MPMediaQuery.songsQuery().items
        
        try! realm.beginWrite()

        for i in mediaItems!
        {
            let newSong = Song()
            guard i.valueForProperty(MPMediaItemPropertyAssetURL) != nil  else
            {
                continue
            }
            
            let objThatExists = realm.objectForPrimaryKey(Song.self, key: i.valueForProperty(MPMediaItemPropertyAssetURL)!.absoluteString)

            guard objThatExists == nil else
            {
                continue
            }
            newSong.audioUrl = i.valueForProperty(MPMediaItemPropertyAssetURL)!.absoluteString

            newSong.id = 0
            guard i.valueForProperty(MPMediaItemPropertyTitle) != nil else
            {
                continue
            }
            newSong.title = i.valueForProperty(MPMediaItemPropertyTitle) as! String
            
            guard i.valueForProperty(MPMediaItemPropertyArtist) != nil else
            {
                continue
            }
            newSong.artist = i.valueForProperty(MPMediaItemPropertyArtist) as! String
            
            if i.valueForProperty(MPMediaItemPropertyIsCloudItem) as! Bool == true
            {
                newSong.downloaded = false
            }
            else
            {
                newSong.downloaded = true
            }
            
            print(i.valueForProperty(MPMediaItemPropertyArtwork))
            if (i.valueForProperty(MPMediaItemPropertyArtwork) == nil)
            {
                
                //SET AS DEFAULT IMG
                
            }
            else
            {
                var newUrl = newSong.artist + (i.valueForProperty(MPMediaItemPropertyAlbumTitle) as! String)
                newUrl = newUrl.stringByReplacingOccurrencesOfString(" ", withString: "")
                newUrl = md5(string: newUrl) + ".png"
                newSong.artworkUrl = newUrl

                let fn = newUrl
                let art = i.valueForProperty(MPMediaItemPropertyArtwork) as! MPMediaItemArtwork
                let v = art.imageWithSize( CGSizeMake (100, 100))
                if let data = UIImagePNGRepresentation(v!) {
                    let filename = userPath.URLByAppendingPathComponent(fn)
                    
                    data.writeToFile(filename.path!, atomically: true)

                }

            }
            newSong.mpItem = true
            realm.add(newSong)

        }
        try! realm.commitWrite()

    }
    
    func getDocumentsDirectory() -> NSURL {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let userDir = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("a@a.com"))
        /* END CLEANUP */
        
        return userDir
    }
    
    
    func sync()
    {
        //let realm = self.newRealm()
        
        let syncUrl = NSURL(string: "http://localhost:3000/api/1/syncWithWeb/")
        
        let request = NSMutableURLRequest(URL: syncUrl!)
        
        let token = KeychainWrapper.stringForKey("authToken")
        print(token)
        request.addValue(String(format: "Token token=%@, user_id=1", token!), forHTTPHeaderField: "Authorization")
        
        request.HTTPMethod = "GET"
        request.timeoutInterval = 10
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request)
        { data, response, error in
            let realm = try! Realm()
            
            if error != nil
            {
                //print("error=\(error.code)")
                //Possibly switch this to segue to loginVC
                exit(0)
            }
            
            //HTTP RESPONSE CODE 200 => SUCCESSFUL LOGIN
            //HTTP RESPONSE CODE 401 => UNAUTHENTICATED ACCESS
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("response was not 200: \(response)")
                    return
                }
            }
    
            let jsonResponse = try!NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
            print (jsonResponse)
            
            let arrayResponse = jsonResponse?.valueForKey("response") as! NSArray
            try! realm.write() {
                
                for object in arrayResponse as! [NSDictionary] {
                    let unsplit = object.valueForKey("file")!.valueForKey("url")! as! String
                    let split = unsplit.characters.split{$0 == "/"}.map(String.init)[2]
                    
                    let check = realm.objects(Song.self).filter("audioUrl == %@", split)
                    guard check.count == 0 else
                    {
                        continue
                    }

                    let newSong = Song(value: ["id" : object.valueForKey("id")!,
                        "title" : object.valueForKey("title")!,
                        "artist" : object.valueForKey("artist")!,
                        "artworkUrl": object.valueForKey("cover_art")!,
                        "audioUrl": split])
                    
                    
                    realm.add(newSong)

                    newSong.getArtwork()
                }
                try! realm.commitWrite()
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("sync_with_realm", object: nil)
                }
                
            }
            
        }
        
        task.resume()
                
    }
    
    
    /*MD5 USED FOR SPEED, SECURITY IS NOT AN ISSUE*/
    
    func md5(string string: String) -> String {
        var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            CC_MD5(data.bytes, CC_LONG(data.length), &digest)
        }
        
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }
    
}

