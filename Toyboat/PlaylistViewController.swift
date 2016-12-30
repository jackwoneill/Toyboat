//
//  PlaylistViewController.swift
//  Toyboat
//
//  Created by Jack O'Neill on 7/6/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import RealmSwift

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    var playlists: Array = [Playlist]()
    //var artists = Set<String>()
    var playlistDic: [String: NSMutableArray] = [:]
    var keys: Array = [String]()
    
    let collation = UILocalizedIndexedCollation.currentCollation()
    
    //var subSongs: Array = [Song]()
    var songs: Array = [Song]()
    
    var task: NSURLSessionDownloadTask!
    var session: NSURLSession!
    var cache:NSCache!
    
    var player: AVPlayer!
    
    var finalizing = false
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var newPlaylistButton: UIButton!
    
    @IBOutlet weak var finishPlaylistButton: UIButton!


    //@IBOutlet weak var finalizePlaylistView: UIView!
    //@IBOutlet weak var finalizePlaylistTableView: UITableView!

    override func viewDidLoad() {
//        let config = Realm.Configuration(
//            // Set the new schema version. This must be greater than the previously used
//            // version (if you've never set a schema version before, the version is 0).
//            schemaVersion: 6,
//            
//            // Set the block which will be called automatically when opening a Realm with
//            // a schema version lower than the one set above
//            migrationBlock: { migration, oldSchemaVersion in
//                // We haven’t migrated anything yet, so oldSchemaVersion == 0
//                if (oldSchemaVersion < 6) {
//                    // Nothing to do!
//                    // Realm will automatically detect new properties and removed properties
//                    // And will update the schema on disk automatically
//                }
//        })
//        
//        // Tell Realm to use this new configuration object for the default Realm
//        Realm.Configuration.defaultConfiguration = config
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        let realm = try! Realm()
        syncWithRealm()


        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(
            self,
            selector: #selector(ArtistsListViewController.syncWithRealm),
            name: "sync_with_realm",
            object: nil
        )
        
        super.viewDidLoad()
        
        self.cache = NSCache()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        
    }
    
    override func viewWillAppear(animated: Bool) {
        //self.syncWithRealm()
        
        
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        guard appDelegate.creatingPlaylist == false else {
            //self.finalizePlaylistView.hidden = false
            //self.finalizePlaylistTableView.hidden = false
            
            let realm = try! Realm()
            
            self.songs.removeAll()
            
            print(appDelegate.newPlaylistIds)
            
            for i in appDelegate.newPlaylistIds {
                self.songs.append(realm.objectForPrimaryKey(Song.self, key: i)!)
            }
            self.tableView.editing = true
            self.finalizing = true
            
            self.newPlaylistButton.hidden = true
            self.finishPlaylistButton.hidden = false

            self.tableView.reloadData()
            
            
            return
        }
        
        super.viewWillAppear(animated)
    }
    
    
    //THIS IS LIKELY NEVER CALLED
    override func viewWillDisappear(animated: Bool) {
        if self.finalizing == true
        {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.newPlaylistIds = Set(self.songs.map {$0.audioUrl})
        }
    
        
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertNewObject(sender: AnyObject) {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    // MARK: - Segues
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "showDetail" {
//            if let indexPath = self.tableView.indexPathForSelectedRow {
//                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
//                
//                controller.navigationItem.leftItemsSupplementBackButton = true
//            }
//        }
//    }
//    
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.finalizing == true {
            return self.songs.count
        }
        
        print(playlists.count)
        return playlists.count

    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard self.finalizing == false else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
            
            cell.textLabel?.text = songs[indexPath.row].title
            return cell
            
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = playlists[indexPath.row].title

        
        
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        var itemToMove = songs[fromIndexPath.row]
        songs.removeAtIndex(fromIndexPath.row)
        songs.insert(itemToMove, atIndex: toIndexPath.row)
    }
    
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func syncWithRealm()
    {
        let realm = try! Realm()
        realm.refresh()
        if let plists = try? realm.objects(Playlist.self)
        {
            print(plists)
            self.playlists = Array(plists)
            
            for p: Playlist in Array(plists) {
                print(p.title)
                
                //print(s.artist.characters.first)
                
                if p.title[p.title.startIndex] >= "0" && p.title[p.title.startIndex] <= "9"
                {
                    if(playlistDic["#"] == nil)
                    {
                        playlistDic["#"] = NSMutableArray()
                    }
                    playlistDic["#"]?.addObject(p)
                    continue
                }
                if p.title[p.title.startIndex] == (" ")
                {
                    if(playlistDic["#"] == nil)
                    {
                        playlistDic["#"] = NSMutableArray()
                    }
                    playlistDic["#"]?.addObject(p)
                    continue
                }
                if (playlistDic["\(p.title[p.title.startIndex])"]) == nil
                {
                    playlistDic["\(p.title[p.title.startIndex])"] = NSMutableArray()
                    
                }
                //Check if first letter is a number
                playlistDic["\(p.title[p.title.startIndex])"]!.addObject(p)
                
                keys = Array(playlistDic.keys)
                keys.sortInPlace({ $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending })
                if keys.count > 0
                {
                    //keys.removeFirst()
                    keys.append("#")
                }
                
            }
            
            
        }
        relDat()
        
        
    }
    
    func relDat()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            guard self.playlists.count > 0 else {
                return
            }
            
            self.tableView.reloadData()
            
        })
    }
    
    
    @IBAction func newPlaylist(sender: AnyObject) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.creatingPlaylist = true
        self.newPlaylistButton.hidden = true
        self.finishPlaylistButton.hidden = false
        tabBarController?.selectedIndex = 0
    }
    
    @IBAction func finalizePlaylist(sender: AnyObject) {
        
        guard self.songs.count > 0 else {
            return
        }
        
        var inputTextField: UITextField!
        
        let alertController = UIAlertController(title: "Name Your New Playlist", message: nil, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            // Do whatever you want with inputTextField?.text
            if(inputTextField!.text?.characters.count != 0)
            {
                let str = String(inputTextField.text!)
              
                self.tableView.editing = false
                self.finishPlaylistButton.hidden = true
                self.newPlaylistButton.hidden = false
                
                let realm = try! Realm()
                realm.beginWrite()
                let newPlaylist = Playlist()
                newPlaylist.title = str
                newPlaylist.list = List(self.songs)
                realm.add(newPlaylist)
                try! realm.commitWrite()

                
                self.songs.removeAll()
                self.finalizing = false
                
                var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.creatingPlaylist = false
                appDelegate.newPlaylistIds.removeAll()
                
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("not_creating_playlist", object: nil)
                }
                
                
                self.syncWithRealm()
                print(str)
                print(newPlaylist)
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in }
        
        alertController.addAction(ok)
        alertController.addAction(cancel)
        
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            inputTextField = textField
        }
        
        presentViewController(alertController, animated: true, completion: nil)
        
    }



 }

