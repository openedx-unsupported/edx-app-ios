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
    
    private let courseID : String
    private let headerContainer = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 44))
    private let lastAccessedView = CourseOutlineHeaderView(frame: CGRectZero, styles: OEXStyles.sharedStyles(), titleText : OEXLocalizedString("LAST_ACCESSED", nil), subtitleText : "Placeholder")
    let refreshController = PullRefreshController()
    
    init(courseID : String) {
        self.courseID = courseID
        super.init(nibName: nil, bundle: nil)
    }

    required init!(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var groups : [CourseOutlineQuerier.BlockGroup] = []
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.registerClass(CourseOutlineHeaderCell.self, forHeaderFooterViewReuseIdentifier: CourseOutlineHeaderCell.identifier)
        tableView.registerClass(CourseVideoTableViewCell.self, forCellReuseIdentifier: CourseVideoTableViewCell.identifier)
        tableView.registerClass(CourseHTMLTableViewCell.self, forCellReuseIdentifier: CourseHTMLTableViewCell.identifier)
        tableView.registerClass(CourseProblemTableViewCell.self, forCellReuseIdentifier: CourseProblemTableViewCell.identifier)
        tableView.registerClass(CourseUnknownTableViewCell.self, forCellReuseIdentifier: CourseUnknownTableViewCell.identifier)
        tableView.registerClass(CourseSectionTableViewCell.self, forCellReuseIdentifier: CourseSectionTableViewCell.identifier)
        
        headerContainer.addSubview(lastAccessedView)
        lastAccessedView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.headerContainer)
        }
        
        refreshController.setupInScrollView(self.tableView)
        
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return groups.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = groups[section]
        return group.children.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Will remove manual heights when dropping iOS7 support and move to automatic cell heights.
        return 60.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = groups[section]
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(CourseOutlineHeaderCell.identifier) as! CourseOutlineHeaderCell
        header.block = group.block
        return header
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let group = groups[indexPath.section]
        let nodes = group.children
        let block = nodes[indexPath.row]
        switch nodes[indexPath.row].displayType {
        case .Video:
            let cell = tableView.dequeueReusableCellWithIdentifier(CourseVideoTableViewCell.identifier, forIndexPath: indexPath) as! CourseVideoTableViewCell
            cell.block = block
            cell.localState = OEXInterface.sharedInterface().stateForVideoWithID(block.blockID, courseID : courseID)
            cell.delegate = self
            return cell
        case .HTML(.Base):
            let cell = tableView.dequeueReusableCellWithIdentifier(CourseHTMLTableViewCell.identifier, forIndexPath: indexPath) as! CourseHTMLTableViewCell
            cell.block = block
            return cell
        case .HTML(.Problem):
            let cell = tableView.dequeueReusableCellWithIdentifier(CourseProblemTableViewCell.identifier, forIndexPath: indexPath) as! CourseProblemTableViewCell
            cell.block = block
            return cell
        case .Unknown:
            let cell = tableView.dequeueReusableCellWithIdentifier(CourseUnknownTableViewCell.identifier, forIndexPath: indexPath) as! CourseUnknownTableViewCell
            cell.block = block
            return cell
        case .Outline, .Unit:
            let cell = tableView.dequeueReusableCellWithIdentifier(CourseSectionTableViewCell.identifier, forIndexPath: indexPath) as! CourseSectionTableViewCell
            cell.block = nodes[indexPath.row]
            cell.delegate = self
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let group = groups[indexPath.section]
        let chosenBlock = group.children[indexPath.row]
        self.delegate?.outlineTableController(self, choseBlock: chosenBlock, withParentID: group.block.blockID)
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.refreshController.scrollViewDidScroll(scrollView)
    }
    
    func videoCellChoseDownload(cell: CourseVideoTableViewCell, block : CourseBlock) {
        self.delegate?.outlineTableController(self, choseDownloadVideosRootedAtBlock: block)
    }
    
    func sectionCellChoseDownload(cell: CourseSectionTableViewCell, block: CourseBlock) {
        self.delegate?.outlineTableController(self, choseDownloadVideosRootedAtBlock: block)
    }
    
    func choseViewLastAccessedWithItem(item : CourseLastAccessed) {
        for group in groups {
            let childNodes = group.children
            let currentLastViewedIndex = childNodes.firstIndexMatching({$0.blockID == item.moduleId})
            if let matchedIndex = currentLastViewedIndex {
                self.delegate?.outlineTableController(self, choseBlock: childNodes[matchedIndex], withParentID: group.block.blockID)
                break
            }
        }
    }
    
    /// Shows the last accessed Header from the item as argument. Also, sets the relevant action if the course block exists in the course outline.
    func showLastAccessedWithItem(item : CourseLastAccessed) {
        tableView.tableHeaderView = self.headerContainer
        lastAccessedView.subtitleText = item.moduleName
        lastAccessedView.setViewButtonAction { [weak self] _ in
            self?.choseViewLastAccessedWithItem(item)
        }
    }
    
    func hideLastAccessed() {
        tableView.tableHeaderView = nil
    }
}