//
//  ArtistsListViewController.swift
//  TB
//
//  Created by Jack O'Neill on 6/21/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//

import UIKit
import RealmSwift
import AVFoundation

class ArtistsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    var songs: Array = [Song]()
    var artists = Set<String>()
    var keyArtistDic: [String: NSMutableSet] = [:]
    var parents: [String: Parent] = [:]
    var totalDic: [String: Int] = [:]

    var songsDic: [String: Artist] = [:]
    var keys: Array = [String]()
    
    let collation = UILocalizedIndexedCollation.currentCollation()
    
    var subSongs: Array = [Song]()
    
    var task: NSURLSessionDownloadTask!
    var session: NSURLSession!
    var cache:NSCache!
    
    var player: AVPlayer!
    
    var creatingPlaylist = false
    
    var selectedIds = Set<String>()
    

    
    @IBOutlet weak var finishPlaylistButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var finishPlaylistView: UIView!
    
    
    
    //var total = 0
    /// The identifier for the parent cells.
    let parentCellIdentifier = "ParentCell"
    
    /// The identifier for the child cells.
    let childCellIdentifier = "ChildCell"
    
    
    
    /// The data source
    
    /// Define wether can exist several cells expanded or not.
    let numberOfCellsExpanded: NumberOfCellExpanded = .One
    
    /// Constant to define the values for the tuple in case of not exist a cell expanded.
    let NoCellExpanded = (-1, -1)
    
    /// The index of the last cell expanded and its parent.
    var lastCellExpanded : (Int, Int)!
    
    override func viewDidLoad() {
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
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        let realm = try! Realm()
        syncWithRealm()
        
        
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.selectedIds = appDelegate.newPlaylistIds
        
        self.lastCellExpanded = NoCellExpanded
        
        self.tabBarController!.delegate = self
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(
            self,
            selector: #selector(ArtistsListViewController.syncWithRealm),
            name: "sync_with_realm",
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(ArtistsListViewController.updatePlaylist),
            name: "update_current_playlist",
            object: nil
        )
        
        super.viewDidLoad()
        
        session = NSURLSession.sharedSession()
        task = NSURLSessionDownloadTask()
        
        self.cache = NSCache()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton

    }
    
    override func viewWillAppear(animated: Bool) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        guard appDelegate.creatingPlaylist == false else {
            self.creatingPlaylist = true
            self.tableView.allowsMultipleSelection = true
            
            //ADD Subview at top
            
            self.finishPlaylistView.hidden = false
            
            return
        }

        super.viewWillAppear(animated)
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
    
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return totalDic.keys.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let key = keys[section]
//        let arr = keyArtistDic[key]?.allObjects
//        //let arts = NSMutableSet(array: keyArtistDic[keys[section]]!.allObjects)
//        var n = 0
//        for i in arr! {
//            n += (songsDic[i as! String]!.songs.count)
//        }
//        return n
        
        return totalDic[keys[section]]!
        
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return keys[section]
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        //return collation.sectionIndexTitles
        return keys
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //self.setParentChildren("#")
        var cell : UITableViewCell!
        
        let arts = keyArtistDic[keys[indexPath.section]]!.allObjects
        print(arts)


        
        let (parent, isParentCell, actualPosition) = self.findParent(indexPath.row, key: keys[indexPath.section])
        
        if !isParentCell {
            
            cell = tableView.dequeueReusableCellWithIdentifier(childCellIdentifier, forIndexPath: indexPath)
            let artist = arts[parent]
            let songs = artist.songs
            
            
            //fails below
            let song = songsDic[arts[parent] as! String]!.songs[indexPath.row - actualPosition - 1]
            //let song = songs![indexPath.row - actualPosition - 1] as! Song
           
            //print(songs![indexPath.row - actualPosition - 1])
            //let song = songs[actualPosition]
            print(indexPath.row)
            print(song.title)
            
            cell.textLabel?.text = song.title

            if (selectedIds.contains(song.audioUrl))
            {
                print(selectedIds)
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                    
                }
                
            }
            
            
            


            //cell.backgroundColor = UIColor.greenColor()
        }
        else {
            print(parent - actualPosition)
            print(arts[parent])
            let artist = songsDic[arts[parent] as! String]
            //above
            let songs = artist!.songs
            //let song = songs[indexPath.row - actualPosition] as! Song
            cell = tableView.dequeueReusableCellWithIdentifier(parentCellIdentifier, forIndexPath: indexPath)
           
            cell.textLabel!.text = artist!.name
            
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        let arts = keyArtistDic[keys[indexPath.section]]!.allObjects

        let (parent, isParentCell, actualPosition) = self.findParent(indexPath.row, key: keys[indexPath.section])
        
        
        guard isParentCell else {
            
            
            guard self.creatingPlaylist == false else
            {
                let artist = songsDic[arts[parent] as! String]
                
                let songs = artist!.songs
                let song = songs[indexPath.row - actualPosition - 1]
                
                selectedIds.insert(song.audioUrl)
                
                return
            }

            let artist = songsDic[arts[parent] as! String]

            let songs = artist!.songs
            let song = songs[indexPath.row - actualPosition - 1]
            
            Playlist.sharedInstance.genRandom(song, all: List(self.songs))
            
            print(song)
            
            var destinationUrl: NSURL = NSURL(string: "")!
            
            if (song.downloaded == true)
            {
                
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
                //THIS NEEDS TO BE SET TO USE WITH USER DIRECTORY, JUST GRAB FROM USER OBJ
                let serverUrl = String("http://localhost:3000/directories/a162ece85e7b1b03128f138dfc63a036196c07b6c7e9ea54/")
                destinationUrl = NSURL(string: [serverUrl,song.audioUrl] 
                    .flatMap{$0}
                    .joinWithSeparator(""))!
                
            }
            
            Player.sharedInstance.playWithURL(destinationUrl)

            
            return
        }
        
        //PARENT CELL SELECTED
        let artist = songsDic[arts[parent] as! String]

        switch (self.songsDic[artist!.name]!.state) {
            
        case .Expanded:
            self.collapseSubItemsAtIndex(indexPath.row, parent: parent, artist: (artist?.name)!, key: keys[indexPath.section],section: indexPath.section)
            self.lastCellExpanded = NoCellExpanded
            break
            
        case .Collapsed:
            self.expandItemAtIndex(indexPath.row, parent: indexPath.row, artist: artist!.name, key: keys[indexPath.section], section: indexPath.section)
            break

        }
        
        let idp = NSIndexPath(forRow: parent, inSection: indexPath.section)
        self.tableView.deselectRowAtIndexPath(idp, animated: false)
        
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        var cell : UITableViewCell!
        
        let (parent, isParentCell, actualPosition) = self.findParent(indexPath.row, key: keys[indexPath.section])
        
        if !isParentCell {
            cell = tableView.dequeueReusableCellWithIdentifier(childCellIdentifier, forIndexPath: indexPath)
            let arts = keyArtistDic[keys[indexPath.section]]
            let artist = arts?.allObjects[parent]
            let songs = artist?.songs
            let song = songs![indexPath.row - actualPosition - 1]
            //let song = self.dataSource[parent].childs[indexPath.row - actualPosition - 1] as! Song
            print(songs![indexPath.row - actualPosition - 1])
            

            
        
            guard self.selectedIds.contains(song.audioUrl) else
            {
                return
            }
            
            self.selectedIds.remove(song.audioUrl)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return !self.findParent(indexPath.row, key: keys[indexPath.section]).isParentCell ? 44.0 : 64.0
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
    
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func syncWithRealm()
    {
        if let sobjs = try? Realm().objects(Song.self)
        {
            print(sobjs)
            self.songs = Array(sobjs)
            
            artists = Set(sobjs.map { $0.artist })
            
            for s: Song in sobjs {
                artists.insert(s.artist)
                
                
                print(s.artist.characters.first)

                
                if s.artist[s.artist.startIndex] >= "0" && s.artist[s.artist.startIndex] <= "9"
                {
                    if(keyArtistDic["#"] == nil)
                    {
                        keyArtistDic["#"] = NSMutableSet()
                        //songsDic["#"] = Artist(name: s.artist, songs: [], state: .Collapsed)

                    }
                    if (totalDic["#"] == nil)
                    {
                        totalDic["#"] = 1
                    }
                    else
                    {
                        totalDic["#"]! += 1
                    }
                    
                    if (songsDic["Unknown Artist"] == nil)
                    {
                        songsDic["Unknown Artist"] = Artist(name: s.artist, songs: [], state: .Collapsed)
                    }
                    
                    keyArtistDic["#"]?.addObject(s.artist)
                    songsDic["Unknown Artist"]?.songs.append(s)
                    
                    continue
                    
                }
                
                /* IF ARTIST NAME IS BLANK */
                if s.artist[s.artist.startIndex] == (" ")
                {
                    if(keyArtistDic["#"] == nil)
                    {
                        keyArtistDic["#"] = NSMutableSet()
                        //songsDic["#"] = Artist(name: s.artist, songs: [], state: .Collapsed)
                        
                    }
                    if (totalDic["#"] == nil)
                    {
                        totalDic["#"] = 1
                    }
                    else
                    {
                        totalDic["#"]! += 1
                    }
                    
                    if (songsDic["Unknown Artist"] == nil)
                    {
                        songsDic["Unknown Artist"] = Artist(name: s.artist, songs: [], state: .Collapsed)
                    }
                    
                    keyArtistDic["#"]?.addObject(s.artist)
                    songsDic["Unknown Artist"]?.songs.append(s)
                    
                    continue
                }
                
                //IF ARTIST NAME NOT BLANK AND DOESN'T BEGIN WITH A NUMBER
                
                //IF KEY DOES NOT EXIST
                if (keyArtistDic["\(s.artist[s.artist.startIndex])"]) == nil
                {
                    keyArtistDic["\(s.artist[s.artist.startIndex])"] = NSMutableSet()
                    //self.setParentChildren(String(s.artist[s.artist.startIndex]))

                }
                
                /* THIS COULD PROBABLY BE COMBINED WITH THE PREVIOUS IF STATEMENT, AS THEY WOULD PRESUMABLE BE TIED */

                
                
                //IF SPECIFIC ARTIST DOES NOT EXIST YET
                if (songsDic[s.artist] == nil)
                {
                    songsDic[s.artist] = Artist(name: s.artist, songs: [], state: .Collapsed)
                    if (totalDic["\(s.artist[s.artist.startIndex])"] == nil)
                    {
                        totalDic["\(s.artist[s.artist.startIndex])"] = 1
                    }
                    else
                    {
                        totalDic["\(s.artist[s.artist.startIndex])"]! += 1
                    }
                }
                
                
                keyArtistDic["\(s.artist[s.artist.startIndex])"]?.addObject(s.artist)
                songsDic[s.artist]?.songs.append(s)
                

            }
            keys = Array(keyArtistDic.keys)
            keys.sortInPlace({ $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending })
            if keys.count > 0
            {
                //keys.removeFirst()
                if (keyArtistDic["#"] != nil)
                {
                    keys.append("#")
                }
            }
            
            
        }
        //self.setParentChildren()
        relDat()
        
        
    }
    
    func relDat()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.tableView.reloadData()
            
        })
    }
    
    func updatePlaylist()
    {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        guard appDelegate.creatingPlaylist == false else {
            appDelegate.newPlaylistIds.unionInPlace(self.selectedIds)
            
            
            return
        }
        
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
        //print(appDelegate.newPlaylistIds)
        
        
        return
        
        
        
    }
    
    private func expandItemAtIndex(index : Int, parent: Int, artist: String, key: String, section: Int) {

        let children = songsDic[artist]?.songs
        
        self.songsDic[artist]!.state = .Expanded
        
        // position to start to insert rows.
        var insertPos = index + 1
        
        let indexPaths = (0..<children!.count).map { _ -> NSIndexPath in
            let indexPath = NSIndexPath(forRow: insertPos, inSection: section )
            insertPos += 1
            return indexPath
        }
        
        self.totalDic[key]! += children!.count

        // insert the new rows
        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
        
    }
    
    /**
     Collapse the cell at the index specified.
     
     - parameter index: The index of the cell to collapse
     */
    private func collapseSubItemsAtIndex(index : Int, parent: Int, artist: String, key: String, section: Int) {
        
        var indexPaths = [NSIndexPath]()
        
        let numChildren = songsDic[artist]!.songs.count
        
        self.totalDic[key]! -= numChildren

        // update the state of the cell.
        self.songsDic[artist]!.state = .Collapsed
        
        guard index + 1 <= index + numChildren else { return }
        
        // create an array of NSIndexPath with the selected positions
        indexPaths = (index + 1...index + numChildren).map { NSIndexPath(forRow: $0, inSection: section)}
        
        // remove the expanded cells
        self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)

    }
    
    /**
     Update the cells to expanded to collapsed state in case of allow severals cells expanded.
     
     - parameter parent: The parent of the cell
     - parameter index:  The index of the cell.
     */
//    private func updateCells(parent: Int, index: Int, key: String, artist: String) {
//        
//        switch (self.songsDic[artist]!.state) {
//            
//        case .Expanded:
//            self.collapseSubItemsAtIndex(index, parent: parent, artist: artist, key: key)
//            self.lastCellExpanded = NoCellExpanded
//            
//        case .Collapsed:
//            switch (numberOfCellsExpanded) {
//            case .One:
//                // exist one cell expanded previously
//                if self.lastCellExpanded != NoCellExpanded {
//                    
//                    let (indexOfCellExpanded, parentOfCellExpanded) = self.lastCellExpanded
//                    
//                    self.collapseSubItemsAtIndex(indexOfCellExpanded, parent: parentOfCellExpanded, artist: artist, key: key)
//                    
//                    // cell tapped is below of previously expanded, then we need to update the index to expand.
//                    if parent > parentOfCellExpanded {
//                        //HEREHERfdsjkafldsafdajskl;fdjskal;fdjsakf;dasjkfdas;
////                        let newIndex = index - self.parents[artists[parentOfCellExpanded]].childs.count
////                        self.expandItemAtIndex(newIndex, parent: parent, key: key)
////                        self.lastCellExpanded = (newIndex, parent)
//                    }
//                    else {
//                        self.expandItemAtIndex(index, parent: parent, artist: artist, key: key)
//                        self.lastCellExpanded = (index, parent)
//                    }
//                }
//                else {
//                    self.expandItemAtIndex(index, parent: parent, artist: artist, key: key)
//                    self.lastCellExpanded = (index, parent)
//                }
//            case .Several:
//                self.expandItemAtIndex(index, parent: parent, artist: artist, key: key)
//            }
//        }
//    }
    
    /**
     Find the parent position in the initial list, if the cell is parent and the actual position in the actual list.
     
     - parameter index: The index of the cell
     
     - returns: A tuple with the parent position, if it's a parent cell and the actual position righ now.
     */
    private func findParent(index : Int, key: String) -> (parent: Int, isParentCell: Bool, actualPosition: Int) {
        
        var position = 0, parent = 0
        guard position < index else { return (parent, true, parent) }
        
        let arts = self.keyArtistDic[key]?.allObjects
        
        //Get artist object
        var item = songsDic[arts![parent] as! String]
        
        repeat {
            
            switch (item!.state) {
            case .Expanded:
                position += item!.songs.count + 1
            case .Collapsed:
                position += 1
            }
            
            parent += 1
            
            
            var n = 0
            for i in arts! {
                n += (songsDic[i as! String]!.songs.count)
            }
            
            if parent < n {
                if (parent < arts?.count)
                {
                    let i = songsDic[arts![parent] as! String]
                    item = self.songsDic[(i!.name)]
                }
            }
            
        } while (position < index)
        
        // if it's a parent cell the indexes are equal.
        if position == index {
            return (parent, position == index, position)
        }
        
        item = songsDic[arts![parent - 1] as! String]
        return (parent - 1, position == index, position - (item?.songs.count)! - 1)
    }
}


extension ArtistsListViewController: UITabBarControllerDelegate {
    
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {

        
        if let myController = viewController as? PlaylistViewController {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            guard appDelegate.creatingPlaylist == false else {
                appDelegate.newPlaylistIds.unionInPlace(self.selectedIds)
                
                
                return true
            }
            // do something
        }
        return true
    }
}
