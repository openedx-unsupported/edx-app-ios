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
        tableView.registerClass(CourseVideoTableViewCell.self, forCellReuseIdentifier: CourseVideoTableViewCell.identifier)
        tableView.registerClass(CourseHTMLTableViewCell.self, forCellReuseIdentifier: CourseHTMLTableViewCell.identifier)
        tableView.registerClass(CourseProblemTableViewCell.self, forCellReuseIdentifier: CourseProblemTableViewCell.identifier)
        tableView.registerClass(CourseUnknownTableViewCell.self, forCellReuseIdentifier: CourseUnknownTableViewCell.identifier)
        tableView.registerClass(CourseOutlineFooterView.self, forHeaderFooterViewReuseIdentifier: CourseOutlineFooterView.identifier)
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
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let isLastSection = section == nodes.count - 1
        if (isLastSection)
        {
            return 110.0
        }
        else
        {
            return 0.0
        }
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let isLastSection = section == nodes.count - 1
        if (isLastSection)
        {
            var footerView = CourseOutlineFooterView(reuseIdentifier: CourseOutlineFooterView.identifier)
            //TODO: Set properties and Actions for the next and previous buttons
            return footerView
        }
        else
        {
            return UIView(frame: CGRectZero)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let node = nodes[indexPath.section]
        if let childNodes = children[node.blockID]?.value {
            switch childNodes[indexPath.row].type{
            case .HTML:
                return 60.0
            case .Video:
                return 60.0
            case .Problem:
                return 60.0
            case .Unknown:
                return 60.0
            default:
                return 40.0
            }
        }
        return 40.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let node = nodes[section]
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(CourseOutlineHeaderCell.identifier) as! CourseOutlineHeaderCell
        header.block = node
        return header
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let node = nodes[indexPath.section]
        if let nodes = children[node.blockID]?.value {
            println(nodes[indexPath.row].type.displayType.hashValue)
            switch nodes[indexPath.row].type
            {
            case .Video:
                var cell = tableView.dequeueReusableCellWithIdentifier(CourseVideoTableViewCell.identifier, forIndexPath: indexPath) as! CourseVideoTableViewCell
                cell.state = CourseVideoState.NotViewed
                cell.block = nodes[indexPath.row]
                return cell
            case .HTML:
                var cell = tableView.dequeueReusableCellWithIdentifier(CourseHTMLTableViewCell.identifier, forIndexPath: indexPath) as! CourseHTMLTableViewCell
                cell.block = nodes[indexPath.row]
                return cell
            case .Problem:
                var cell = tableView.dequeueReusableCellWithIdentifier(CourseProblemTableViewCell.identifier, forIndexPath: indexPath) as! CourseProblemTableViewCell
                cell.block = nodes[indexPath.row]
                return cell
            case .Unknown:
                var cell = tableView.dequeueReusableCellWithIdentifier(CourseUnknownTableViewCell.identifier, forIndexPath: indexPath) as! CourseUnknownTableViewCell
                cell.block = nodes[indexPath.row]
                return cell
            default:
                var cell = tableView.dequeueReusableCellWithIdentifier(CourseOutlineTableViewCell.identifier, forIndexPath: indexPath) as! CourseOutlineTableViewCell
                cell.block = nodes[indexPath.row]
                return cell
                }
            

            }
    return UITableViewCell();
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let node = nodes[indexPath.section]
        if let nodes = children[node.blockID]?.value {
            let chosenBlock = nodes[indexPath.row]
            self.delegate?.outlineTableController(self, choseBlock: chosenBlock, withParentID: node.blockID)
        }
    }
}