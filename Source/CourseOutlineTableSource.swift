//
//  CourseOutlineTableSource.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let defaultAspectRatio:CGFloat = 0.533
private let lassAccessViewPortraitHeight:CGFloat = 72
private let lassAccessViewLandscapeHeight:CGFloat = 52

protocol CourseOutlineTableControllerDelegate : class {
    func outlineTableController(controller : CourseOutlineTableController, choseBlock:CourseBlock, withParentID:CourseBlockID)
    func outlineTableController(controller : CourseOutlineTableController, choseDownloadVideos videos:[OEXHelperVideoDownload], rootedAtBlock block: CourseBlock)
    func outlineTableController(controller : CourseOutlineTableController, choseDownloadVideoForBlock block:CourseBlock)
    func outlineTableControllerChoseShowDownloads(controller : CourseOutlineTableController)
    func outlineTableControllerReload(controller: CourseOutlineTableController)
}

class CourseOutlineTableController : UITableViewController, CourseVideoTableViewCellDelegate, CourseSectionTableViewCellDelegate {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & NetworkManagerProvider & OEXConfigProvider & OEXRouterProvider
    
    weak var delegate : CourseOutlineTableControllerDelegate?
    private let environment : Environment
    let courseQuerier : CourseOutlineQuerier
    let courseID : String
    private var courseOutlineMode: CourseOutlineMode
    
    private let courseCard = CourseCardView(frame: CGRect.zero)
    private var courseCertificateView : CourseCertificateView?
    private let headerContainer = UIView()
    private let lastAccessedView = CourseOutlineHeaderView(frame: CGRect.zero, styles: OEXStyles.shared(), titleText : Strings.lastAccessed, subtitleText : "Placeholder")
    private var lastAccess:Bool = false
    private var shouldHideCourseCard:Bool = false
    let refreshController = PullRefreshController()
    
    init(environment : Environment, courseID : String, forMode mode: CourseOutlineMode) {
        self.courseID = courseID
        self.environment = environment
        self.courseOutlineMode = mode
        self.courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var groups : [CourseOutlineQuerier.BlockGroup] = []
    var highlightedBlockID : CourseBlockID? = nil
    
    func addCertificateView() {
        guard environment.config.isTabLayoutEnabled, environment.config.certificatesEnabled, let enrollment = environment.interface?.enrollmentForCourse(withID: courseID), let certificateUrl = enrollment.certificateUrl, let certificateImage = UIImage(named: "courseCertificate") else { return }
        
        let certificateItem =  CourseCertificateIem(certificateImage: certificateImage, certificateUrl: certificateUrl, action: {[weak self] _ in
            if let weakSelf = self, let url = NSURL(string: certificateUrl) {
                weakSelf.environment.router?.showCertificate(url: url, title: enrollment.course.name, fromController: weakSelf)
            }
        })
        courseCertificateView = CourseCertificateView(certificateItem: certificateItem)
        if let courseCertificateView = courseCertificateView {
            headerContainer.addSubview(courseCertificateView)
        }
    }
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.register(CourseOutlineHeaderCell.self, forHeaderFooterViewReuseIdentifier: CourseOutlineHeaderCell.identifier)
        tableView.register(CourseVideoTableViewCell.self, forCellReuseIdentifier: CourseVideoTableViewCell.identifier)
        tableView.register(CourseHTMLTableViewCell.self, forCellReuseIdentifier: CourseHTMLTableViewCell.identifier)
        tableView.register(CourseProblemTableViewCell.self, forCellReuseIdentifier: CourseProblemTableViewCell.identifier)
        tableView.register(CourseUnknownTableViewCell.self, forCellReuseIdentifier: CourseUnknownTableViewCell.identifier)
        tableView.register(CourseSectionTableViewCell.self, forCellReuseIdentifier: CourseSectionTableViewCell.identifier)
        tableView.register(DiscussionTableViewCell.self, forCellReuseIdentifier: DiscussionTableViewCell.identifier)
        headerContainer.addSubview(lastAccessedView)
        headerContainer.addSubview(courseCard)
        addCertificateView()
        
        if let course = environment.interface?.enrollmentForCourse(withID: courseID)?.course, environment.config.isTabLayoutEnabled {
            CourseCardViewModel.onCourseOutline(course: course).apply(card: courseCard, networkManager: environment.networkManager)
            refreshTableHeaderView(lastAccess: false)
            tableView.setAndLayoutTableHeaderView(header: headerContainer)
            
        }
        
        refreshController.setupInScrollView(scrollView: tableView)
    }
    
    private func indexPathForBlockWithID(blockID : CourseBlockID) -> NSIndexPath? {
        for (i, group) in groups.enumerated() {
            for (j, block) in group.children.enumerated() {
                if block.blockID == blockID {
                    return IndexPath(row: j, section: i) as NSIndexPath
                }
            }
        }
        return nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let path = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: path, animated: false)
        }
        if let highlightID = highlightedBlockID, let indexPath = indexPathForBlockWithID(blockID: highlightID)
        {
            tableView.scrollToRow(at: indexPath as IndexPath, at: UITableViewScrollPosition.middle, animated: false)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        refreshTableHeaderView(lastAccess: lastAccess)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = groups[section]
        return group.children.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Will remove manual heights when dropping iOS7 support and move to automatic cell heights.
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = groups[section]
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CourseOutlineHeaderCell.identifier) as! CourseOutlineHeaderCell
        header.block = group.block
        return header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = groups[indexPath.section]
        let nodes = group.children
        let block = nodes[indexPath.row]
        switch nodes[indexPath.row].displayType {
        case .Video:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseVideoTableViewCell.identifier, for: indexPath as IndexPath) as! CourseVideoTableViewCell
            cell.block = block
            cell.courseID = courseID
            cell.localState = environment.dataManager.interface?.stateForVideo(withID: block.blockID, courseID : courseQuerier.courseID)
            cell.delegate = self
            cell.swipeCellViewDelegate = (courseOutlineMode == .Video) ? cell : nil
            return cell
        case .HTML(.Base):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseHTMLTableViewCell.identifier, for: indexPath) as! CourseHTMLTableViewCell
            cell.block = block
            return cell
        case .HTML(.Problem):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseProblemTableViewCell.identifier, for: indexPath) as! CourseProblemTableViewCell
            cell.block = block
            return cell
        case .Unknown:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseUnknownTableViewCell.identifier, for: indexPath) as! CourseUnknownTableViewCell
            cell.block = block
            return cell
        case .Outline, .Unit:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseSectionTableViewCell.identifier, for: indexPath) as! CourseSectionTableViewCell
            cell.block = nodes[indexPath.row]
            let courseID = courseQuerier.courseID
            cell.videos = courseQuerier.supportedBlockVideos(forCourseID: courseID, blockID: block.blockID)
            cell.swipeCellViewDelegate = (courseOutlineMode == .Video) ? cell : nil
            cell.delegate = self
            cell.courseID = courseID
            return cell
        case .Discussion:
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionTableViewCell.identifier, for: indexPath) as! DiscussionTableViewCell
            cell.block = block
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? CourseBlockContainerCell else {
            assertionFailure("All course outline cells should implement CourseBlockContainerCell")
            return
        }
        
        let highlighted = cell.block?.blockID != nil && cell.block?.blockID == self.highlightedBlockID
        cell.applyStyle(style: highlighted ? .Highlighted : .Normal)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = groups[indexPath.section]
        let chosenBlock = group.children[indexPath.row]
        self.delegate?.outlineTableController(controller: self, choseBlock: chosenBlock, withParentID: group.block.blockID)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? SwipeableCell, cell.state != .initial  else {
            return indexPath
        }
        
        return nil
    }
    
    func videoCellChoseDownload(cell: CourseVideoTableViewCell, block : CourseBlock) {
        self.delegate?.outlineTableController(controller: self, choseDownloadVideoForBlock: block)
    }
    
    func videoCellChoseShowDownloads(cell: CourseVideoTableViewCell) {
        self.delegate?.outlineTableControllerChoseShowDownloads(controller: self)
    }
    
    func reloadCell(cell: UITableViewCell) {
        self.delegate?.outlineTableControllerReload(controller: self)
    }
    
    func sectionCellChoseShowDownloads(cell: CourseSectionTableViewCell) {
        self.delegate?.outlineTableControllerChoseShowDownloads(controller: self)
    }
    
    func sectionCellChoseDownload(cell: CourseSectionTableViewCell, videos: [OEXHelperVideoDownload], forBlock block : CourseBlock) {
        self.delegate?.outlineTableController(controller: self, choseDownloadVideos: videos, rootedAtBlock:block)
    }
    
    func choseViewLastAccessedWithItem(item : CourseLastAccessed) {
        for group in groups {
            let childNodes = group.children
            let currentLastViewedIndex = childNodes.firstIndexMatching({$0.blockID == item.moduleId})
            if let matchedIndex = currentLastViewedIndex {
                self.delegate?.outlineTableController(controller: self, choseBlock: childNodes[matchedIndex], withParentID: group.block.blockID)
                break
            }
        }
    }
    
    /// Shows the last accessed Header from the item as argument. Also, sets the relevant action if the course block exists in the course outline.
    func showLastAccessedWithItem(item : CourseLastAccessed) {
        lastAccessedView.subtitleText = item.moduleName
        lastAccessedView.setViewButtonAction { [weak self] _ in
            self?.choseViewLastAccessedWithItem(item: item)
        }
        
        refreshTableHeaderView(lastAccess: true)
    }
    
    func hideLastAccessed() {
        refreshTableHeaderView(lastAccess: false)
    }
    
    func hideTableHeaderView() {
        shouldHideCourseCard = true
        tableView.tableHeaderView = nil
    }
    
    private func refreshTableHeaderView(lastAccess: Bool) {
        var constraintView: UIView = courseCard
        if shouldHideCourseCard { return }
        self.lastAccess = lastAccess
        lastAccessedView.isHidden = !lastAccess
        
        courseCard.snp_remakeConstraints { (make) in
            let screenWidth = UIScreen.main.bounds.size.width
            if courseOutlineMode != .Full || !environment.config.isTabLayoutEnabled || shouldHideCourseCard {
                make.height.equalTo(0)
            }
            else {
                let screenHeight = UIScreen.main.bounds.size.height
                let halfScreehHeight = screenHeight / 2
                let ratioedHeight = screenWidth * defaultAspectRatio
                let _ = (halfScreehHeight > ratioedHeight) ? make.height.equalTo(ratioedHeight): make.height.equalTo(halfScreehHeight)
            }
            make.trailing.equalTo(headerContainer)
            make.leading.equalTo(headerContainer)
            make.width.equalTo(screenWidth)
            make.top.equalTo(headerContainer)
        }
        if let courseCertificateView = courseCertificateView {
            courseCertificateView.snp_remakeConstraints { (make) -> Void in
                make.trailing.equalTo(courseCard)
                make.leading.equalTo(courseCard)
                make.height.equalTo(CourseCertificateView.height)
                make.top.equalTo(constraintView.snp_bottom)
            }
            constraintView = courseCertificateView
        }
        
        lastAccessedView.snp_remakeConstraints { (make) -> Void in
            make.trailing.equalTo(courseCard)
            make.leading.equalTo(courseCard)
            make.top.equalTo(constraintView.snp_bottom)
            let _ = lastAccess ? (isVerticallyCompact() ? make.height.equalTo(lassAccessViewLandscapeHeight) : make.height.equalTo(lassAccessViewPortraitHeight)) : make.height.equalTo(0)
            make.bottom.equalTo(headerContainer)
        }
        tableView.setAndLayoutTableHeaderView(header: headerContainer)
    }
}

extension UITableView {
    //set the tableHeaderView so that the required height can be determined, update the header's frame and set it again
    func setAndLayoutTableHeaderView(header: UIView) {
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let size = header.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        header.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        tableHeaderView = header
    }
}

