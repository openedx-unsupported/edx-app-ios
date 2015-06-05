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

class CourseOutlineTableController : UITableViewController, CourseVideoTableViewCellDelegate, CourseSectionTableViewCellDelegate {
    weak var delegate : CourseOutlineTableControllerDelegate?
    
    let courseID : String
    
    init(courseID : String) {
        self.courseID = courseID
        super.init(nibName: nil, bundle: nil)
    }

    required init!(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var nodes : [CourseBlock] = []
    var children : [CourseBlockID : [CourseBlock]] = [:]
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.registerClass(CourseOutlineHeaderCell.self, forHeaderFooterViewReuseIdentifier: CourseOutlineHeaderCell.identifier)
        tableView.registerClass(CourseVideoTableViewCell.self, forCellReuseIdentifier: CourseVideoTableViewCell.identifier)
        tableView.registerClass(CourseHTMLTableViewCell.self, forCellReuseIdentifier: CourseHTMLTableViewCell.identifier)
        tableView.registerClass(CourseUnknownTableViewCell.self, forCellReuseIdentifier: CourseUnknownTableViewCell.identifier)
        tableView.registerClass(CourseSectionTableViewCell.self, forCellReuseIdentifier: CourseSectionTableViewCell.identifier)
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
            switch nodes[indexPath.row].displayType {
            case .Video:
                let cell = tableView.dequeueReusableCellWithIdentifier(CourseVideoTableViewCell.identifier, forIndexPath: indexPath) as! CourseVideoTableViewCell
                cell.block = block
                cell.localState = OEXInterface.sharedInterface().stateForVideoWithID(block.blockID, courseID : courseID)
                cell.delegate = self
                return cell
            case .HTML:
                let cell = tableView.dequeueReusableCellWithIdentifier(CourseHTMLTableViewCell.identifier, forIndexPath: indexPath) as! CourseHTMLTableViewCell
                cell.block = block
                cell.kind = CourseHTMLTableViewCell.kindForBlockType(block.type)
                return cell
            case .Unknown:
                let cell = tableView.dequeueReusableCellWithIdentifier(CourseUnknownTableViewCell.identifier, forIndexPath: indexPath) as! CourseUnknownTableViewCell
                cell.block = block
                return cell
            case .Outline, .Unit:
                var cell = tableView.dequeueReusableCellWithIdentifier(CourseSectionTableViewCell.identifier, forIndexPath: indexPath) as! CourseSectionTableViewCell
                cell.block = nodes[indexPath.row]
                cell.delegate = self
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
    
    func sectionCellChoseDownload(cell: CourseSectionTableViewCell, block: CourseBlock) {
        self.delegate?.outlineTableController(self, choseDownloadVideosRootedAtBlock: block)
    }
}