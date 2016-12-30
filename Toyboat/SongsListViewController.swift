//
//  MasterViewController.swift
//  TB
//
//  Created by Jack O'Neill on 6/21/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import UIKit
import RealmSwift
import MediaPlayer


class SongsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var songs: Array = [Song]()
    var songsDic: [String: NSMutableArray] = [:]
    var keys: Array = [String]()
    
    let collation = UILocalizedIndexedCollation.currentCollation()
    
    var task: NSURLSessionDownloadTask!
    var session: NSURLSession!
    var cache:NSCache!
    
    var creatingPlaylist = false
    
    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    var documentsDirectory: AnyObject! = nil
    var userDir: NSURL! = nil
    
    @IBOutlet weak var finishPlaylistButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var finishPlaylistView: UIView!
    
    @IBOutlet var playerContainerView: UIView!
    
    override func viewDidLoad() {
        
        let rlm = try! Realm()
        if rlm.objects(Song).isEmpty
        {
            //Ask to import
        }
        
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(
            self,
            selector: #selector(SongsListViewController.syncWithRealm),
            name: "sync_with_realm",
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(SongsListViewController.notCreatingPlaylist),
            name: "not_creating_playlist",
            object: nil)
        
        notificationCenter.addObserver(
            self,
            selector: #selector(SongsListViewController.expandPlayer),
            name: "expand_player",
            object: nil)
        
        self.documentsDirectory = self.paths[0]
        self.userDir = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("a@a.com"))
        
        super.viewDidLoad()
        
        //syncWithRealm()

        self.cache = NSCache()

        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton


    }
    
    override func viewWillAppear(animated: Bool) {
        
        NSNotificationCenter.defaultCenter().postNotificationName("update_current_playlist", object: nil)
        
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        guard appDelegate.creatingPlaylist == false else {
            self.creatingPlaylist = true
            self.tableView.allowsMultipleSelection = true

            //ADD Subview at top
            
            self.finishPlaylistView.hidden = false
            
            return
        }
        super.viewWillAppear(animated)
        
        return

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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showPlayer" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                //let controller = (segue.destinationViewController as! UINavigationController).topViewController as! PlayerViewController
                let controller = segue.destinationViewController as! PlayerViewController
                
                return
            }
        }
        
        if segue.identifier == "EmbedSegue" {
            let vc = segue.destinationViewController as? PlaylistViewController
            vc?.view.frame.size.height = UIScreen.mainScreen().bounds.height
            print(vc?.view.frame.size.height)
//            /self.embeddedViewController = vc
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        guard self.creatingPlaylist == false else
        {
            return false
        }
        print("kek")
        print(identifier)
        return true
        
    }
    
    // MARK: - Table View
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    
        return songsDic.keys.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if songsDic[keys[section]] == nil {
            return 0
        }
        return songsDic[keys[section]]!.count
    }

    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return keys[section]
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        //return collation.sectionIndexTitles
        return keys
    }
    
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return collation.sectionForSectionIndexTitleAtIndex(index)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let song = songsDic[keys[indexPath.section]]![indexPath.row] as! Song
        
        cell.textLabel!.text = song.title
        
        //PUT THIS IN A grabArtwork() method that returns the image
        guard (!song.artworkUrl.isEmpty) else
        {
            return cell
        }

        if (self.cache.objectForKey(song.artworkUrl) != nil){
            // 2
            cell.imageView?.image = self.cache.objectForKey(song.artworkUrl) as? UIImage
        }else{

            // CREATE PATH TO FILE
            let pathToArtwork = userDir.URLByAppendingPathComponent(song.artworkUrl)

            // check if it exists before downloading it
            if NSFileManager().fileExistsAtPath(pathToArtwork.path!) {
                if let data = NSData(contentsOfFile: pathToArtwork.path!)
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        // 5
                        if let updateCell = tableView.cellForRowAtIndexPath(indexPath) {
                            let img:UIImage! = UIImage(data: data)
                            updateCell.imageView?.image = img
                            self.cache.setObject(img, forKey: song.artworkUrl)
                            
                            //USE THIS NEXT LINE IF IMAGES ARENT LOADING IN CELL
                            //FIND WAY TO DO THIS ONLY FOR FIRST X CELLS
                            cell.setNeedsLayout()
                        }
                    })
                }

            
            }


            // 3
//            let artworkUrl = song.artworkUrl 
//            let url:NSURL! = NSURL(string: artworkUrl)
//            task = session.downloadTaskWithURL(url, completionHandler: { (location, response, error) -> Void in
//                if let data = NSData(contentsOfURL: url){
//                    // 4
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        // 5
//                        if let updateCell = tableView.cellForRowAtIndexPath(indexPath) {
//                            let img:UIImage! = UIImage(data: data)
//                            updateCell.imageView?.image = img
//                            self.cache.setObject(img, forKey: indexPath.row)
//                        }
//                    })
//                }
//            })
            //task.resume()
        }
        return cell

    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard self.creatingPlaylist == false else
        {
            let song = songsDic[keys[indexPath.section]]![indexPath.row] as! Song
            let ad = UIApplication.sharedApplication().delegate as! AppDelegate

            ad.newPlaylistIds.insert(song.audioUrl)
            //print(ad.newPlaylistIds)
            
            return
        }
        
        
        let song = songsDic[keys[indexPath.section]]![indexPath.row] as! Song
        
        var destinationUrl: NSURL = NSURL(string: "")!
        
        if (song.downloaded == true)
        {
            if song.mpItem == true
            {
                destinationUrl = NSURL(string: song.audioUrl)!
            }
            else
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
        }
        else
        {
            if song.mpItem == true
            {
                destinationUrl = NSURL(string: song.audioUrl)!
            }
            else
            {
                let serverUrl = String("http://localhost:3000/directories/a162ece85e7b1b03128f138dfc63a036196c07b6c7e9ea54/")
                destinationUrl = NSURL(string: [serverUrl,song.audioUrl]
                    .flatMap{$0}
                    .joinWithSeparator(""))!
            }
            
        }
        
        //self.player = try! AVPlayer(URL: destinationUrl)
        Playlist.sharedInstance.genRandom(song, all: List(self.songs))

        Player.sharedInstance.playWithURL(destinationUrl)
        self.performSegueWithIdentifier("showPlayer", sender: self)
        
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let song = songsDic[keys[indexPath.section]]![indexPath.row] as! Song
        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
        
        guard ad.newPlaylistIds.contains(song.audioUrl) else
        {
            return
        }
        
        ad.newPlaylistIds.remove(song.audioUrl)
    }
    
    
    /* ADD THE 'DOWNLOAD/DELETE' OPTIONS ON ROW SWIPE*/
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]?
    {
        let song = self.songsDic[self.keys[indexPath.section]]![indexPath.row] as! Song
        var downloadOrUnload = UITableViewRowAction(style: .Normal, title: "Error") { action, index in
        }
        let realm = try! Realm()
        if song.downloaded == false
            /* DOWNLOAD */
        {
            downloadOrUnload = UITableViewRowAction(style: .Normal, title: "Download") { action, index in
                
                song.download()
                
                realm.beginWrite()
                
                song.downloaded = true
                try! realm.commitWrite()
                
                tableView.setEditing(false, animated: true)
            }
            downloadOrUnload.backgroundColor = UIColor.greenColor()
        }
        else
            /* UNLOAD */
        {
            downloadOrUnload = UITableViewRowAction(style: .Normal, title: "Unload") { action, index in
                song.unload()
                
                realm.beginWrite()
                
                song.downloaded = false
                try! realm.commitWrite()
                
                tableView.setEditing(false, animated: true)
            }
            downloadOrUnload.backgroundColor = UIColor.orangeColor()
            
        }
        
        let delete = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
            
            self.songsDic[self.keys[indexPath.section]]!.removeObjectAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
            if(self.songsDic[self.keys[indexPath.section]]!.count == 0)
            {
                self.songsDic.removeValueForKey(self.keys[indexPath.section])
                self.keys.removeAtIndex(indexPath.section)
                tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Fade)
            }
        }
        delete.backgroundColor = UIColor.redColor()
        
        return [delete, downloadOrUnload]
    }

    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    func syncWithRealm()
    {

        if let sobjs = try? Realm().objects(Song.self)
        {
            
            self.songs = Array(sobjs)
            //self.songs.appendContentsOf(media)
            
            for s: Song in songs {
                
                    if s.title.characters.first >= "0" && s.title.characters.first <= "9"
                    {
                        if(songsDic["#"] == nil)
                        {
                            songsDic["#"] = NSMutableArray()
                        }
                        songsDic["#"]?.addObject(s)
                        continue
                    }
                    if s.title.characters.first == (" ")
                    {
                        if(songsDic["#"] == nil)
                        {
                            songsDic["#"] = NSMutableArray()
                        }
                        songsDic["#"]?.addObject(s)
                        continue
                    }
                    if (songsDic["\(s.title.characters.first!)"]) == nil
                    {
                        songsDic["\(s.title.characters.first!)"] = NSMutableArray()
                        
                    }
                    //Check if first letter is a number
                    songsDic["\(s.title.characters.first!)"]!.addObject(s)
                
                keys = Array(songsDic.keys)
                keys.sortInPlace({ $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending })
                if keys.count > 0
                {
                    keys.removeFirst()
                    keys.append("#")
                }

            }
            

        }
        relDat()
        
    }
    
    func relDat()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
                self.tableView.reloadData()

        })

    }
    
    func notCreatingPlaylist()
    {
        self.creatingPlaylist = false
        self.tableView.allowsMultipleSelection = false
        
        //ADD Subview at top
        
        self.finishPlaylistView.hidden = true
    }
    
    func expandPlayer()
    {
        UIView.animateWithDuration(1.0, animations: {
            if PlayerViewController.sharedInstance.expanded == false
            {
                self.playerContainerView.frame.origin.y = 0
            }
            else
            {
                self.playerContainerView.frame.origin.y =  UIScreen.mainScreen().bounds.height - (self.tabBarController?.tabBar.frame.height)! - 50
                self.playerContainerView.frame = CGRect(x: 0,
                    y: UIScreen.mainScreen().bounds.height - (self.tabBarController?.tabBar.frame.height)! - 50,
                    width: UIScreen.mainScreen().bounds.width,
                    height: UIScreen.mainScreen().bounds.height)

            }
            
        })
        self.playerContainerView.frame = CGRect(x: 0,
                                                y: UIScreen.mainScreen().bounds.height - (self.tabBarController?.tabBar.frame.height)! - 50,
                                                width: UIScreen.mainScreen().bounds.width,
                                                height: UIScreen.mainScreen().bounds.height)
    }
    
    
    @IBAction func didFinalizePlaylist(sender: AnyObject) {
        
        //CODE FROM CRYPTALERTER TO SHOW ALERT VIEW
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        guard appDelegate.newPlaylistIds.count > 0 else {
            self.creatingPlaylist = false
            self.tableView.allowsMultipleSelection = false
            
            //Hide View at top
            
            self.finishPlaylistView.hidden = true
            return
        }
        
        //REDIRECT TO VIEWCONTROLLER TO RE-ORDER SONGS/DELETE UNWANTED SONGS
        
        tabBarController?.selectedIndex = 2
        
        return

        
    }
    


}


