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
    let headerContainer = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 44))
    let lastAccessedView = CourseOutlineHeaderView(frame: CGRectZero, styles: OEXStyles.sharedStyles(), titleLabelString: OEXLocalizedString("LAST_ACCESSED", nil), subtitleLabelString : "Placeholder")
    
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
        
        headerContainer.addSubview(lastAccessedView)
        lastAccessedView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.headerContainer)
        }
        
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return nodes.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let blockID = nodes[section].blockID
        return children[blockID]?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0 // TODO: real height
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
    
    /// Shows the last accessed Header from the item as argument. Also, sets the relevant action if the course block exists in the course outline.
    func showLastAccessedWithItem(item : CourseLastAccessed) {
        tableView.tableHeaderView = self.headerContainer
        lastAccessedView.subtitleText = item.moduleName
        lastAccessedView.setViewButtonAction({ [weak self] (sender:AnyObject) -> Void in
            if let owner = self {
                for node in owner.nodes {
                    if let childNodes = owner.children[node.blockID] {
                        let currentLastViewedIndex = childNodes.firstIndexMatching({$0.blockID == item.moduleId})
                        if let matchedIndex = currentLastViewedIndex {
                            owner.delegate?.outlineTableController(owner, choseBlock: childNodes[matchedIndex], withParentID: node.blockID)
                            break
                        }
                        
                    }
                }
            }
        })
    }
}