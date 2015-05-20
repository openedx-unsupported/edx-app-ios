//
//  MenuOptionsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol MenuOptionsDelegate {
    func optionSelected(selectedRow: Int)
}

let MENU_WIDTH : CGFloat = 120.0
let MENU_HEIGHT : CGFloat = 90.0

class MenuOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    
    var tableView: UITableView?
    var options: [String]!
    var selectedOptionIndex: Int!
    var delegate​: MenuOptionsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: MENU_WIDTH, height: MENU_HEIGHT), style: .Plain)
        if let theTableView = tableView {
            theTableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "reuseIdentifier")
            theTableView.separatorStyle = .None
            theTableView.dataSource = self
            theTableView.delegate = self
            
            theTableView.layer.borderColor = UIColor.lightGrayColor().CGColor
            theTableView.layer.borderWidth = 1.0
            
            view.addSubview(theTableView)
        }
        tableView!.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = UIFont.systemFontOfSize(12)
        if indexPath.row == selectedOptionIndex {
            cell.textLabel?.textColor = UIColor(red: 17 / 255, green: 137 / 255, blue: 227 / 255, alpha: 1.0)
        }
        else {
            cell.textLabel?.textColor = UIColor.grayColor()
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate​?.optionSelected(indexPath.row)
    }
    

    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 30
    }
    
}
