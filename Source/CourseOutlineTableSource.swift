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
    func outlineTableController(controller : CourseOutlineTableController, choseDownloadVideosRootedAtBlock:CourseBlock)
}

class CourseOutlineTableController : UITableViewController, CourseVideoTableViewCellDelegate {
    weak var delegate : CourseOutlineTableControllerDelegate?
    
    var nodes : [CourseBlock] = []
    var children : [CourseBlockID : [CourseBlock]] = [:]
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.registerClass(CourseOutlineTableViewCell.self, forCellReuseIdentifier: CourseOutlineTableViewCell.identifier)
        tableView.registerClass(CourseOutlineHeaderCell.self, forHeaderFooterViewReuseIdentifier: CourseOutlineHeaderCell.identifier)
        tableView.registerClass(CourseVideoTableViewCell.self, forCellReuseIdentifier: CourseVideoTableViewCell.identifier)
        tableView.registerClass(CourseHTMLTableViewCell.self, forCellReuseIdentifier: CourseHTMLTableViewCell.identifier)
        tableView.registerClass(CourseProblemTableViewCell.self, forCellReuseIdentifier: CourseProblemTableViewCell.identifier)
        tableView.registerClass(CourseUnknownTableViewCell.self, forCellReuseIdentifier: CourseUnknownTableViewCell.identifier)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return nodes.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let blockID = nodes[section].blockID
        return children[blockID]?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0 // TODO real height
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Will remove manual heights when dropping iOS7 support and move to automatic cell heights.
        return 60.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let node = nodes[section]
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(CourseOutlineHeaderCell.identifier) as! CourseOutlineHeaderCell
        header.block = node
        return header
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let node = nodes[indexPath.section]
        if let nodes = children[node.blockID] {
            let block = nodes[indexPath.row]
            switch nodes[indexPath.row].type {
            case .Video:
                let cell = tableView.dequeueReusableCellWithIdentifier(CourseVideoTableViewCell.identifier, forIndexPath: indexPath) as! CourseVideoTableViewCell
                cell.block = block
                cell.state = OEXInterface.sharedInterface().watchedStateForVideoWithID(block.blockID)
                cell.delegate = self
                return cell
            case .HTML:
                let cell = tableView.dequeueReusableCellWithIdentifier(CourseHTMLTableViewCell.identifier, forIndexPath: indexPath) as! CourseHTMLTableViewCell
                cell.block = block
                return cell
            case .Problem:
                let cell = tableView.dequeueReusableCellWithIdentifier(CourseProblemTableViewCell.identifier, forIndexPath: indexPath) as! CourseProblemTableViewCell
                cell.block = block
                return cell
            case .Unknown:
                let cell = tableView.dequeueReusableCellWithIdentifier(CourseUnknownTableViewCell.identifier, forIndexPath: indexPath) as! CourseUnknownTableViewCell
                cell.block = block
                return cell
            default:
                let cell = tableView.dequeueReusableCellWithIdentifier(CourseOutlineTableViewCell.identifier, forIndexPath: indexPath) as! CourseOutlineTableViewCell
                cell.block = nodes[indexPath.row]
                return cell
            }
        }
        assertionFailure("Control reached undesireable state at index : \(indexPath.row)");
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let node = nodes[indexPath.section]
        if let nodes = children[node.blockID] {
            let chosenBlock = nodes[indexPath.row]
            self.delegate?.outlineTableController(self, choseBlock: chosenBlock, withParentID: node.blockID)
        }
    }
    
    func videoCellChoseDownload(cell: CourseVideoTableViewCell, block : CourseBlock) {
        self.delegate?.outlineTableController(self, choseDownloadVideosRootedAtBlock: block)
    }
}