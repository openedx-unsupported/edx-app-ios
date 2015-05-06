//
//  CourseOutlineTableSource.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol CourseOutlineTableControllerDelegate : class {
    func outlineTableController(controller : CourseOutlineTableController, choseBlock:CourseBlock, withParentID:CourseBlockID)
}

class CourseOutlineTableController : UITableViewController {
    weak var delegate : CourseOutlineTableControllerDelegate?
    
    var nodes : [CourseBlock] = []
    var children : [CourseBlockID : Promise<[CourseBlock]>] = [:]
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(CourseOutlineTableViewCell.self, forCellReuseIdentifier: CourseOutlineTableViewCell.identifier)
        tableView.registerClass(CourseOutlineHeaderCell.self, forHeaderFooterViewReuseIdentifier: CourseOutlineHeaderCell.identifier)
    }
    
    var allLoaded : Bool {
        let result = reduce(children.values, true) {
            $0 && $1.value != nil
        }
        return result
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return nodes.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = nodes[section].children.count
        return count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0 // TODO real height
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let node = nodes[section]
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(CourseOutlineHeaderCell.identifier) as! CourseOutlineHeaderCell
        header.block = node
        return header
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CourseOutlineTableViewCell.identifier, forIndexPath: indexPath) as! CourseOutlineTableViewCell
        let node = nodes[indexPath.section]
        if let nodes = children[node.blockID]?.value {
            cell.block = nodes[indexPath.row]
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let node = nodes[indexPath.section]
        if let nodes = children[node.blockID]?.value {
            let chosenBlock = nodes[indexPath.row]
            self.delegate?.outlineTableController(self, choseBlock: chosenBlock, withParentID: node.blockID)
        }
    }
}