//
//  CourseOutlineTableSource.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let resumeCourseViewPortraitHeight: CGFloat = 72
private let resumeCourseViewLandscapeHeight: CGFloat = 52
private let courseUpgradeViewtHeight: CGFloat = 62

protocol CourseOutlineTableControllerDelegate: AnyObject {
    func outlineTableController(controller: CourseOutlineTableController, choseBlock block: CourseBlock, parent: CourseBlockID)
    func outlineTableController(controller: CourseOutlineTableController, resumeCourse item: ResumeCourseItem)
    func outlineTableController(controller: CourseOutlineTableController, choseDownloadVideos videos: [OEXHelperVideoDownload], rootedAtBlock block: CourseBlock)
    func outlineTableController(controller: CourseOutlineTableController, choseDownloadVideoForBlock block: CourseBlock)
    func outlineTableControllerChoseShowDownloads(controller: CourseOutlineTableController)
    func outlineTableControllerReload(controller: CourseOutlineTableController)
    func resetCourseDate(controller: CourseOutlineTableController)
}

public class CourseOutlineTableController: UITableViewController, ScrollableDelegateProvider {

    typealias Environment = DataManagerProvider & OEXInterfaceProvider & NetworkManagerProvider & OEXConfigProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXStylesProvider & ServerConfigProvider
    
    weak var delegate: CourseOutlineTableControllerDelegate?
    weak var newDashboardDelegate: NewCourseDashboardViewControllerDelegate?
    
    private let environment: Environment
    private let courseID: String
    private var courseOutlineMode: CourseOutlineMode
    private var courseBlockID: CourseBlockID?
    private let courseQuerier: CourseOutlineQuerier
    
    private let courseDateBannerView = CourseDateBannerView(frame: .zero)
    private let courseCard = CourseCardView(frame: .zero)
    private var courseCertificateView: CourseCertificateView?
    private let headerContainer = UIView()
    
    private lazy var resumeCourseHeaderView = ResumeCourseHeaderView()
    private lazy var resumeCourseView = CourseOutlineHeaderView(frame: .zero, styles: OEXStyles.shared(), titleText: Strings.resume, subtitleText: "Placeholder")
    private lazy var valuePropView = UIView()

    var courseVideosHeaderView: CourseVideosHeaderView?
    let refreshController = PullRefreshController()
        
    private var isResumeCourse = false
    private var shouldHideTableViewHeader: Bool = false
    
    weak public var scrollableDelegate: ScrollableDelegate?
    private var scrollByDragging = false
        
    private var collapsedSections = Set<Int>()
    private var hasAddedToCollapsedSections = false
    
    var highlightedBlockID : CourseBlockID? = nil
    private var groups : [CourseOutlineQuerier.BlockGroup] = []
    private var videos: [OEXHelperVideoDownload]?
    private var watchedVideoBlock: [CourseBlockID] = []
    
    var isSectionOutline = false {
        didSet {
            if isSectionOutline || environment.config.isNewDashboardEnabled {
                hideTableHeaderView()
            }
            
            tableView.reloadData()
        }
    }
    
    init(environment: Environment, courseID: String, forMode mode: CourseOutlineMode, courseBlockID: CourseBlockID? = nil) {
        self.courseID = courseID
        self.courseBlockID = courseBlockID
        self.environment = environment
        self.courseOutlineMode = mode
        self.courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addCertificateView() {
        guard environment.config.certificatesEnabled, let enrollment = enrollment, let certificateUrl =  enrollment.certificateUrl, let certificateImage = UIImage(named: "courseCertificate") else { return }

        let certificateItem =  CourseCertificateIem(certificateImage: certificateImage, certificateUrl: certificateUrl, action: {[weak self] in
            if let weakSelf = self, let url = NSURL(string: certificateUrl) {
                weakSelf.environment.router?.showCertificate(url: url, title: enrollment.course.name, fromController: weakSelf)
            }
        })
        courseCertificateView = CourseCertificateView(certificateItem: certificateItem)
        if let courseCertificateView = courseCertificateView {
            headerContainer.addSubview(courseCertificateView)
        }
    }

    private var canShowValueProp: Bool {
        guard let enrollment = enrollment else { return false }
        return enrollment.isUpgradeable && environment.serverConfig.valuePropEnabled
    }

    private var enrollment: UserCourseEnrollment? {
        return environment.interface?.enrollmentForCourse(withID: courseID)
    }

    private func setAccessibilityIdentifiers() {
        tableView.accessibilityIdentifier = "CourseOutlineTableController:table-view"
        headerContainer.accessibilityIdentifier = "CourseOutlineTableController:header-container"
        courseVideosHeaderView?.accessibilityIdentifier = "CourseOutlineTableController:course-videos-header-view"
        courseCertificateView?.accessibilityIdentifier = "CourseOutlineTableController:certificate-view"
        resumeCourseView.accessibilityIdentifier = "CourseOutlineTableController:resume-course-view"
        courseCard.accessibilityIdentifier = "CourseOutlineTableController:course-card"
        valuePropView.accessibilityIdentifier = "CourseOutlineTableController:value-prop-view"
    }
    
    public override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.register(CourseOutlineHeaderCell.self, forHeaderFooterViewReuseIdentifier: CourseOutlineHeaderCell.identifier)
        tableView.register(CourseVideoTableViewCell.self, forCellReuseIdentifier: CourseVideoTableViewCell.identifier)
        tableView.register(CourseHTMLTableViewCell.self, forCellReuseIdentifier: CourseHTMLTableViewCell.identifier)
        tableView.register(CourseOpenAssesmentTableViewCell.self, forCellReuseIdentifier: CourseOpenAssesmentTableViewCell.identifier)
        tableView.register(CourseProblemTableViewCell.self, forCellReuseIdentifier: CourseProblemTableViewCell.identifier)
        tableView.register(CourseUnknownTableViewCell.self, forCellReuseIdentifier: CourseUnknownTableViewCell.identifier)
        tableView.register(CourseSectionTableViewCell.self, forCellReuseIdentifier: CourseSectionTableViewCell.identifier)
        tableView.register(DiscussionTableViewCell.self, forCellReuseIdentifier: DiscussionTableViewCell.identifier)
        
        if !environment.config.isNewDashboardEnabled || courseOutlineMode != .full {
            configureOldHeaderView()
        }
        
        refreshController.setupInScrollView(scrollView: tableView)
        setAccessibilityIdentifiers()
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXDownloadDeleted.rawValue) { _, observer, _ in
            observer.tableView.reloadData()
        }
    }
    
    private func configureNewHeaderView() {
        headerContainer.addSubview(resumeCourseHeaderView)
        tableView.tableHeaderView = headerContainer
        
        resumeCourseHeaderView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer)
            make.bottom.equalTo(headerContainer).inset(StandardVerticalMargin * 2)
            make.leading.equalTo(headerContainer).offset(StandardHorizontalMargin)
            make.trailing.equalTo(headerContainer).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 5)
        }
        
        tableView.setAndLayoutTableHeaderView(header: headerContainer)
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    private func configureOldHeaderView() {
        if courseOutlineMode == .full {
            courseDateBannerView.delegate = self
            headerContainer.addSubview(courseDateBannerView)
            headerContainer.addSubview(courseCard)
            headerContainer.addSubview(resumeCourseView)
            addCertificateView()
            addValuePropView()
            
            courseDateBannerView.snp.remakeConstraints { make in
                make.trailing.equalTo(headerContainer)
                make.leading.equalTo(headerContainer)
                make.top.equalTo(headerContainer)
                make.height.equalTo(0)
            }
        }
        if let course = enrollment?.course {
            switch courseOutlineMode {
            case .full:
                CourseCardViewModel.onCourseOutline(course: course).apply(card: courseCard, networkManager: environment.networkManager)
                break
            case .video:
                if let courseBlockID = courseBlockID {
                    let stream = courseQuerier.supportedBlockVideos(forCourseID: courseID, blockID: courseBlockID)
                    stream.listen(self) {[weak self] downloads in
                        self?.videos = downloads.value?.filter { $0.summary?.isDownloadableVideo ?? false }
                        self?.addBulkDownloadHeaderView(course: course, videos: self?.videos)
                    }
                }
                else {
                    videos = environment.interface?.downloadableVideos(of: course)
                    addBulkDownloadHeaderView(course: course, videos: videos)
                }
                break
            }
            refreshTableHeaderView(isResumeCourse: false)
        }
    }
    
    private func addBulkDownloadHeaderView(course: OEXCourse, videos: [OEXHelperVideoDownload]?) {
        courseVideosHeaderView = CourseVideosHeaderView(with: course, environment: environment, videos: videos, blockID: courseBlockID)
        courseVideosHeaderView?.delegate = self
        if let headerView = courseVideosHeaderView {
            headerContainer.addSubview(headerView)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let path = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: path, animated: false)
        }

        if let highlightID = highlightedBlockID,
           let indexPath = indexPathForBlockWithID(blockID: highlightID) {
            tableView.scrollToRow(at: indexPath as IndexPath, at: UITableView.ScrollPosition.middle, animated: false)
        }

        courseOutlineMode == .video ? courseVideosHeaderView?.refreshView() : nil
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        refreshTableHeaderView(isResumeCourse: isResumeCourse)
    }
    
    private func shouldApplyNewStyle(_ group: CourseOutlineQuerier.BlockGroup) -> Bool {
        return environment.config.isNewDashboardEnabled && group.block.type == .Chapter && courseOutlineMode == .full
    }
    
    // MARK: UITableView DataSource & Delegate
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shouldApplyNewStyle(groups[section])
            ? collapsedSections.contains(section) ? 0 : groups[section].children.count
            : groups[section].children.count
    }
    
    public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return shouldApplyNewStyle(groups[section]) ? StandardVerticalMargin * 7.5 : StandardVerticalMargin * 3.75
    }
    
    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CourseOutlineHeaderCell.identifier) as! CourseOutlineHeaderCell
        
        let group = groups[section]
        header.section = section
        header.block = group.block
        header.delegate = self
        
        let allCompleted = allBlocksCompleted(for: group)
        
        if shouldApplyNewStyle(group) {
            header.setupViewsNewDesign(isExpanded: !collapsedSections.contains(section), isCompleted: allCompleted)
        } else {
            header.setupViewsForOldDesign()
        }
        
        allCompleted ? header.showCompletedBackground() : header.showNeutralBackground()
        
        return header
    }
    
    public override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return shouldApplyNewStyle(groups[section]) ? StandardVerticalMargin * 2 : 0
    }
    
    public override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return shouldApplyNewStyle(groups[section]) ? UIView() : nil
    }
    
    public override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = groups[indexPath.section]
        let nodes = group.children
        let block = nodes[indexPath.row]

        switch nodes[indexPath.row].displayType {
        case .Video:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseVideoTableViewCell.identifier, for: indexPath as IndexPath) as! CourseVideoTableViewCell
            cell.isSectionOutline = isSectionOutline
            cell.courseOutlineMode = courseOutlineMode
            cell.localState = environment.dataManager.interface?.stateForVideo(withID: block.blockID, courseID : courseQuerier.courseID)
            cell.block = block
            cell.courseID = courseID
            cell.delegate = self
            cell.swipeCellViewDelegate = (courseOutlineMode == .video) ? cell : nil
            return cell
        case .HTML(.Base), .HTML(.DragAndDrop), .HTML(.WordCloud), .HTML(.LTIConsumer):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseHTMLTableViewCell.identifier, for: indexPath) as! CourseHTMLTableViewCell
            cell.isSectionOutline = isSectionOutline
            cell.block = block
            return cell
        case .HTML(.Problem):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseProblemTableViewCell.identifier, for: indexPath) as! CourseProblemTableViewCell
            cell.isSectionOutline = isSectionOutline
            cell.block = block
            return cell
        case .HTML(.OpenAssesment):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseOpenAssesmentTableViewCell.identifier, for: indexPath) as! CourseOpenAssesmentTableViewCell
            cell.isSectionOutline = isSectionOutline
            cell.block = block
            return cell
        case .Unknown:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseUnknownTableViewCell.identifier, for: indexPath) as! CourseUnknownTableViewCell
            cell.isSectionOutline = isSectionOutline
            cell.block = block
            return cell
        case .Outline, .Unit:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseSectionTableViewCell.identifier, for: indexPath) as! CourseSectionTableViewCell
            cell.completionAction = { [weak self] in
                guard let weakSelf = self else { return }
                if !weakSelf.watchedVideoBlock.contains(block.blockID) {
                    weakSelf.watchedVideoBlock.append(block.blockID)
                    weakSelf.tableView.reloadSections([indexPath.section], with: .none)
                }
            }
            cell.courseOutlineMode = courseOutlineMode
            cell.courseQuerier = courseQuerier
            cell.block = nodes[indexPath.row]
            let courseID = courseQuerier.courseID
            cell.videos = courseQuerier.supportedBlockVideos(forCourseID: courseID, blockID: block.blockID)
            cell.swipeCellViewDelegate = (courseOutlineMode == .video) ? cell : nil
            cell.delegate = self
            cell.courseID = courseID
            cell.selectionStyle = .none
            return cell
        case .Discussion:
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionTableViewCell.identifier, for: indexPath) as! DiscussionTableViewCell
            cell.block = block
            cell.isSectionOutline = isSectionOutline
            return cell
        }
    }
    
    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? CourseBlockContainerCell else {
            assertionFailure("All course outline cells should implement CourseBlockContainerCell")
            return
        }
        
        let highlighted = cell.block?.blockID != nil && cell.block?.blockID == self.highlightedBlockID
        cell.applyStyle(style: highlighted ? .Highlighted : .Normal)
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = groups[indexPath.section]
        let chosenBlock = group.children[indexPath.row]
        delegate?.outlineTableController(controller: self, choseBlock: chosenBlock, parent: group.block.blockID)
    }
    
    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let cell = tableView.cellForRow(at: indexPath) as? SwipeableCell, cell.state != .initial  else {
            return indexPath
        }
        
        return nil
    }
    
    deinit {
        courseQuerier.remove(observer: self)
        NotificationCenter.default.removeObserver(self)
    }
}

extension CourseOutlineTableController {
    func setGroups(_ groups: [CourseOutlineQuerier.BlockGroup]) {
        self.groups = groups
        let collapsedSectionsBeforeReload = collapsedSections
        collapsedSections = Set<Int>(0..<numberOfSections(in: tableView)).filter { collapsedSectionsBeforeReload.contains($0) }
        courseQuerier.remove(observer: self)
        
        var firstIncompleteSection: Int?
        
        for (index, group) in groups.enumerated() {
            let observer = BlockCompletionObserver(controller: self, blockID: group.block.blockID, mode: courseOutlineMode, delegate: self)
            courseQuerier.add(observer: observer)
            
            if firstIncompleteSection == nil && !allBlocksCompleted(for: group) && !hasAddedToCollapsedSections {
                firstIncompleteSection = index
            }
            
            if let firstIncompleteSection = firstIncompleteSection {
                if index > firstIncompleteSection {
                    collapsedSections.insert(index)
                }
            } else {
                let completedChildren = group.children.filter { $0.isCompleted }
                if collapsedSections.isEmpty && !completedChildren.isEmpty && !collapsedSections.contains(index) {
                    collapsedSections.insert(index)
                }
            }
        }
        
        hasAddedToCollapsedSections = true
        UIView.performWithoutAnimation { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    private func allBlocksCompleted(for group: CourseOutlineQuerier.BlockGroup) -> Bool {
        if courseOutlineMode == .video {
            return group.block.type == .Unit ?
                group.children.allSatisfy { $0.isCompleted } :
                group.children.map { $0.blockID }.allSatisfy(watchedVideoBlock.contains)
        } else {
            return group.children.allSatisfy { $0.isCompleted }
        }
    }
    
    private func indexPathForBlockWithID(blockID: CourseBlockID) -> IndexPath? {
        for (i, group) in groups.enumerated() {
            if let j = group.children.firstIndex(where: { $0.blockID == blockID }) {
                return IndexPath(row: j, section: i)
            }
        }
        return nil
    }
    
    private func addValuePropView() {
        if !canShowValueProp { return }

        headerContainer.addSubview(valuePropView)
        valuePropView.backgroundColor = environment.styles.standardBackgroundColor()

        valuePropView.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
        let lockedImage = Icon.Closed.imageWithFontSize(size: 20).image(with: OEXStyles.shared().neutralWhiteT())
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = lockedImage
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: -4, width: image.size.width, height: image.size.height)
        }
        let attributedImageString = NSAttributedString(attachment: imageAttachment)
        let style = OEXTextStyle(weight: .semiBold, size: .base, color: environment.styles.neutralWhiteT())
        let attributedStrings = [
            attributedImageString,
            NSAttributedString(string: "\u{200b}"),
            style.attributedString(withText: Strings.ValueProp.courseDashboardButtonTitle)
        ]
        let attributedTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
        
        let button = UIButton(type: .system)
        button.oex_addAction({ [weak self] _ in
            if let course = self?.enrollment?.course {
                self?.environment.router?.showValuePropDetailView(from: self, screen: .courseDashboard, course: course) {
                    self?.environment.analytics.trackValuePropModal(with: .CourseDashboard, courseId: course.course_id ?? "")
                }
                self?.environment.analytics.trackValuePropLearnMore(courseID: course.course_id ?? "", screenName: .CourseDashboard)
            }
        }, for: .touchUpInside)

        button.backgroundColor = environment.styles.secondaryDarkColor()
        button.setAttributedTitle(attributedTitle, for: .normal)
        valuePropView.addSubview(button)

        button.snp.remakeConstraints { make in
            make.height.equalTo(StandardVerticalMargin * 4.5)
            make.leading.equalTo(valuePropView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(valuePropView).inset(StandardHorizontalMargin)
            make.center.equalTo(valuePropView)
        }
    }
    
    private func resumeCourse(with item: ResumeCourseItem) {
        delegate?.outlineTableController(controller: self, resumeCourse: item)
        environment.analytics.trackResumeCourseTapped(courseID: courseID, blockID: item.lastVisitedBlockID)
    }
    
    /// Shows the last accessed Header from the item as argument. Also, sets the relevant action if the course block exists in the course outline.
    func showResumeCourse(item: ResumeCourseItem) {
        if environment.config.isNewDashboardEnabled {
            showResumeCourseNewDesign(item: item)
        } else {
            showResumeCourseOldDesign(item: item)
        }
    }
    
    func showResumeCourseNewDesign(item: ResumeCourseItem) {
        if !item.lastVisitedBlockID.isEmpty {
            courseQuerier.blockWithID(id: item.lastVisitedBlockID).extendLifetimeUntilFirstResult { [weak self] block in
                self?.configureNewHeaderView()
                self?.resumeCourseHeaderView.tapAction = { [weak self] in
                    self?.resumeCourse(with: item)
                }
            } failure: { [weak self] _ in
                self?.tableView.tableHeaderView = nil
            }
        }
    }
    
    func showResumeCourseOldDesign(item: ResumeCourseItem) {
        if !item.lastVisitedBlockID.isEmpty {
            courseQuerier.blockWithID(id: item.lastVisitedBlockID).extendLifetimeUntilFirstResult { [weak self] block in
                self?.resumeCourseView.subtitleText = block.displayName
                self?.resumeCourseView.setViewButtonAction { [weak self] _ in
                    self?.resumeCourse(with: item)
                }
                self?.refreshTableHeaderView(isResumeCourse: true)
            } failure: { [weak self] _ in
                self?.refreshTableHeaderView(isResumeCourse: false)
            }
        } else {
            refreshTableHeaderView(isResumeCourse: false)
        }
    }
    
    func hideResumeCourse() {
        refreshTableHeaderView(isResumeCourse: false)
    }
    
    func hideTableHeaderView() {
        shouldHideTableViewHeader = true
        tableView.tableHeaderView = nil
    }
    
    func showCourseDateBanner(bannerInfo: DatesBannerInfo) {
        if environment.config.isNewDashboardEnabled {
            if bannerInfo.status == .resetDatesBanner {
                showCourseDates(bannerInfo: bannerInfo, delegate: self)
            }
            return
        }
       
        if canShowValueProp && bannerInfo.status == .resetDatesBanner {
            courseDateBannerView.bannerInfo = bannerInfo
            updateCourseDateBannerView(show: true)
        }
        else if !canShowValueProp {
            courseDateBannerView.bannerInfo = bannerInfo
            updateCourseDateBannerView(show: true)
        }
    }
    
    func hideCourseDateBanner() {
        if environment.config.isNewDashboardEnabled {
            hideCourseDates()
            return
        }
        courseDateBannerView.bannerInfo = nil
        updateCourseDateBannerView(show: false)
    }
    
    private func updateCourseDateBannerView(show: Bool) {
        if shouldHideTableViewHeader { return }

        if courseOutlineMode == .full {
            var height: CGFloat = 0
            
            if show {
                courseDateBannerView.setupView()
                trackDateBannerAppearanceEvent()
                height = courseDateBannerView.heightForView(width: headerContainer.frame.size.width)
            }
            
            courseDateBannerView.snp.remakeConstraints { make in
                make.trailing.equalTo(headerContainer)
                make.leading.equalTo(headerContainer)
                make.top.equalTo(headerContainer)
                make.height.equalTo(height)
            }
            
            updateHeaderConstraints()
            
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    private func updateHeaderConstraints() {
        if shouldHideTableViewHeader {
            tableView.tableHeaderView = nil
            return
        }
        
        if environment.config.isNewDashboardEnabled {
            updateNewHeaderConstraints()
        } else {
            updateOldHeaderConstraints()
        }

        tableView.setAndLayoutTableHeaderView(header: headerContainer)
    }
    
    private func updateNewHeaderConstraints() {
        
    }
    
    private func updateOldHeaderConstraints() {
        var constraintView: UIView = courseCard
        courseCard.snp.remakeConstraints { make in
            make.trailing.equalTo(headerContainer)
            make.leading.equalTo(headerContainer)
            make.top.equalTo(courseDateBannerView.snp.bottom)
            make.height.equalTo(CourseCardView.cardHeight())
        }
        
        if let courseCertificateView = courseCertificateView {
            courseCertificateView.snp.remakeConstraints { make in
                make.trailing.equalTo(courseCard)
                make.leading.equalTo(courseCard)
                make.height.equalTo(CourseCertificateView.height)
                make.top.equalTo(constraintView.snp.bottom)
            }
            constraintView = courseCertificateView
        }

        if canShowValueProp {
            if !headerContainer.subviews.contains(valuePropView) {
                // ideally it should not happen, but in any case,
                // if after course upgradation, value prop is removed, re add it to header view
                addValuePropView()
            }
            valuePropView.snp.remakeConstraints { make in
                make.trailing.equalTo(courseCard)
                make.leading.equalTo(courseCard)
                make.top.equalTo(constraintView.snp.bottom)
                make.height.equalTo(courseUpgradeViewtHeight)
            }
            constraintView = valuePropView
        }
        else {
            valuePropView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
        }
        
        resumeCourseView.snp.remakeConstraints { make in
            make.trailing.equalTo(courseCard)
            make.leading.equalTo(courseCard)
            make.top.equalTo(constraintView.snp.bottom)
            let height = isResumeCourse ? (isVerticallyCompact() ? resumeCourseViewLandscapeHeight : resumeCourseViewPortraitHeight) : 0
            make.height.equalTo(height)
            make.bottom.equalTo(headerContainer)
        }
    }
    
    private func refreshTableHeaderView(isResumeCourse: Bool) {
        if environment.config.isNewDashboardEnabled && courseOutlineMode == .full { return }
        
        self.isResumeCourse = isResumeCourse
        resumeCourseView.isHidden = !isResumeCourse
        
        switch courseOutlineMode {
        case .full:
            if shouldHideTableViewHeader { return }
            updateHeaderConstraints()
            break
        case .video:
            if let course = enrollment?.course, courseBlockID == nil {
                videos = environment.interface?.downloadableVideos(of: course)
                courseVideosHeaderView?.videos = videos ?? []
            }
            if videos?.count ?? 0 <= 0 {
                tableView.tableHeaderView = nil
                return
            }
            courseVideosHeaderView?.snp.makeConstraints { make in
                make.edges.equalTo(headerContainer)
                make.height.equalTo(CourseVideosHeaderView.height * 2)
            }
            courseVideosHeaderView?.refreshView()
            tableView.setAndLayoutTableHeaderView(header: headerContainer)
            break
        }
    }
    
    private func trackDateBannerAppearanceEvent() {
        guard let eventName = courseDateBannerView.bannerInfo?.status?.analyticsEventName,
           let bannerType = courseDateBannerView.bannerInfo?.status?.analyticsBannerType,
           let courseMode = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.mode else { return }
        environment.analytics.trackDatesBannerAppearence(screenName: AnalyticsScreenName.CourseDashboard, courseMode: courseMode, eventName: eventName, bannerType: bannerType)
    }
}

extension CourseOutlineTableController: CourseVideoTableViewCellDelegate {
    func videoCellChoseDownload(cell: CourseVideoTableViewCell, block : CourseBlock) {
        delegate?.outlineTableController(controller: self, choseDownloadVideoForBlock: block)
    }
    
    func videoCellChoseShowDownloads(cell: CourseVideoTableViewCell) {
        delegate?.outlineTableControllerChoseShowDownloads(controller: self)
    }
    
    func reloadCell(cell: UITableViewCell) {
        delegate?.outlineTableControllerReload(controller: self)
    }
}

extension CourseOutlineTableController: CourseSectionTableViewCellDelegate {
    func sectionCellChoseShowDownloads(cell: CourseSectionTableViewCell) {
        delegate?.outlineTableControllerChoseShowDownloads(controller: self)
    }
    
    func sectionCellChoseDownload(cell: CourseSectionTableViewCell, videos: [OEXHelperVideoDownload], forBlock block : CourseBlock) {
        delegate?.outlineTableController(controller: self, choseDownloadVideos: videos, rootedAtBlock:block)
    }
    
    func reloadSectionCell(cell: UITableViewCell) {
        delegate?.outlineTableControllerReload(controller: self)
    }
}

extension CourseOutlineTableController: CourseShiftDatesDelegate {
    func courseShiftDateButtonAction() {
        delegate?.resetCourseDate(controller: self)
    }
}

extension CourseOutlineTableController: CourseVideosHeaderViewDelegate {
    func courseVideosHeaderViewTapped() {
        delegate?.outlineTableControllerChoseShowDownloads(controller: self)
    }
    
    func invalidOrNoNetworkFound() {
        showOverlay(withMessage: environment.interface?.networkErrorMessage() ?? Strings.noWifiMessage)
    }
    
    func didTapVideoQuality() {
        environment.analytics.trackEvent(with: AnalyticsDisplayName.CourseVideosDownloadQualityClicked, name: AnalyticsEventName.CourseVideosDownloadQualityClicked)
        environment.router?.showDownloadVideoQuality(from: self, delegate: self, modal: true)
    }
}

extension CourseOutlineTableController: VideoDownloadQualityDelegate {
    func didUpdateVideoQuality() {
        if courseOutlineMode == .video {
            courseVideosHeaderView?.refreshView()
        }
    }
}

extension CourseOutlineTableController: BlockCompletionDelegate {
    func didCompletionChanged(in blockGroup: CourseOutlineQuerier.BlockGroup, mode: CourseOutlineMode) {
        
        if mode != courseOutlineMode { return }
        
        guard let index = groups.firstIndex(where: { return $0.block.blockID == blockGroup.block.blockID }) else { return }
        
        if tableView.isValidSection(with: index) {
            if mode == .full {
                groups[index] = blockGroup
            }
            tableView.reloadSections([index], with: .none)
        }
    }
}

extension CourseOutlineTableController {
    public override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollByDragging = true
    }
    
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollByDragging {
            scrollableDelegate?.scrollViewDidScroll(scrollView: scrollView)
        }
    }
    
    public override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollByDragging = false
    }
}

extension CourseOutlineTableController: CourseOutlineHeaderCellDelegate {
    func toggleSection(section: Int) {
        if environment.config.isNewDashboardEnabled {
            collapsedSections = collapsedSections.symmetricDifference([section])
            tableView.reloadSections([section], with: .none)
        }
    }
}

extension CourseOutlineTableController: NewCourseDashboardViewControllerDelegate {
    public func showCourseDates(bannerInfo: DatesBannerInfo?, delegate: CourseOutlineTableController?) {
        newDashboardDelegate?.showCourseDates(bannerInfo: bannerInfo, delegate: self)
    }
    
    public func hideCourseDates() {
        newDashboardDelegate?.hideCourseDates()
    }
}

extension CourseOutlineTableController {
    var t_groupsCount: Int {
        return groups.count
    }
}

extension UITableView {
    //set the tableHeaderView so that the required height can be determined, update the header's frame and set it again
    func setAndLayoutTableHeaderView(header: UIView) {
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        header.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        tableHeaderView = header
    }
    
    func isValidSection(with index: Int) -> Bool {
        return index < numberOfSections
    }
}
