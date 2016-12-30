//
//  ArtistsCell.swift
//  Toyboat
//
//  Created by Jack O'Neill on 7/2/16.
//  Copyright © 2016 Jack O'Neill. All rights reserved.
//


import UIKit

class ArtistsCell: UITableViewCell,UITableViewDataSource,UITableViewDelegate {
    
    
    var dataArr:[String] = []
    var subMenuTable:UITableView?
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style , reuseIdentifier: reuseIdentifier)
        setUpTable()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        setUpTable()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpTable()
    }
    
    func setUpTable()
    {
        subMenuTable = UITableView(frame: CGRectZero, style:UITableViewStyle.Plain)
        subMenuTable?.delegate = self
        subMenuTable?.dataSource = self
        self.addSubview(subMenuTable!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        subMenuTable?.frame = CGRectMake(0.2, 0.3, self.bounds.size.width-5, self.bounds.size.height-5)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("cellID")
        
        if(cell == nil){
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cellID")
        }
        
        cell?.textLabel?.text = dataArr[indexPath.row]
        
        return cell!
    }
}