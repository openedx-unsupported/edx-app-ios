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

class CourseOutlineTableController : UITableViewController, CourseVideoTableViewCellDelegate, CourseSectionTableViewCellDelegate, CourseVideosHeaderViewDelegate, VideoDownloadQualityDelegate {

    typealias Environment = DataManagerProvider & OEXInterfaceProvider & NetworkManagerProvider & OEXConfigProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXStylesProvider & RemoteConfigProvider
    
    weak var delegate: CourseOutlineTableControllerDelegate?
    private let environment: Environment
    let courseQuerier: CourseOutlineQuerier
    let courseID: String
    private var courseOutlineMode: CourseOutlineMode
    
    private let courseDateBannerView = CourseDateBannerView(frame: .zero)
    private let courseCard = CourseCardView(frame: .zero)
    private var courseCertificateView: CourseCertificateView?
    private let headerContainer = UIView()
    private lazy var resumeCourseView = CourseOutlineHeaderView(frame: .zero, styles: OEXStyles.shared(), titleText: Strings.resume, subtitleText: "Placeholder")
    private lazy var valuePropView = UIView()
    
    var courseVideosHeaderView: CourseVideosHeaderView?
    private var isResumeCourse = false
    private var shouldHideTableViewHeader:Bool = false
    let refreshController = PullRefreshController()
    private var courseBlockID: CourseBlockID?
    
    var isSectionOutline = false {
        didSet {
            if isSectionOutline {
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
    
    var groups : [CourseOutlineQuerier.BlockGroup] = [] {
        didSet {
            courseQuerier.remove(observer: self)
            groups.forEach { group in
                let observer = BlockCompletionObserver(controller: self, blockID: group.block.blockID, mode: courseOutlineMode, delegate: self)
                courseQuerier.add(observer: observer)
            }            
        }
    }
    
    var highlightedBlockID : CourseBlockID? = nil
    private var videos: [OEXHelperVideoDownload]?
    
    private var watchedVideoBlock: [CourseBlockID] = []
    
    func addCertificateView() {
        guard environment.config.certificatesEnabled, let enrollment = environment.interface?.enrollmentForCourse(withID: courseID), let certificateUrl =  enrollment.certificateUrl, let certificateImage = UIImage(named: "courseCertificate") else { return }

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
        return enrollment?.type == .audit && environment.remoteConfig.valuePropEnabled
    }

    private var enrollment: UserCourseEnrollment? {
        return environment.interface?.enrollmentForCourse(withID: courseID)
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

    private func setAccessibilityIdentifiers() {
        tableView.accessibilityIdentifier = "CourseOutlineTableController:table-view"
        headerContainer.accessibilityIdentifier = "CourseOutlineTableController:header-container"
        courseVideosHeaderView?.accessibilityIdentifier = "CourseOutlineTableController:course-videos-header-view"
        courseCertificateView?.accessibilityIdentifier = "CourseOutlineTableController:certificate-view"
        resumeCourseView.accessibilityIdentifier = "CourseOutlineTableController:resume-course-view"
        courseCard.accessibilityIdentifier = "CourseOutlineTableController:course-card"
        valuePropView.accessibilityIdentifier = "CourseOutlineTableController:value-prop-view"
    }
    
    override func viewDidLoad() {
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
        configureHeaderView()
        refreshController.setupInScrollView(scrollView: tableView)

        setAccessibilityIdentifiers()
        if courseOutlineMode == .full {
            addObservers()
        }
    }

    private func addObservers() {
        NotificationCenter.default.oex_addObserver(observer: self, name: CourseUpgradeCompletionNotification) { notification, observer, _ in
            observer.makeCourseUpgradeComplete()
        }
    }

    private func makeCourseUpgradeComplete() {
        enrollment?.type = .verified
        valuePropView.removeFromSuperview()
        updateHeaderConstraints()
    }
    
    private func configureHeaderView() {
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
        if let course = environment.interface?.enrollmentForCourse(withID: courseID)?.course {
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
        
        refreshTableHeaderView(isResumeCourse: false)
    }
    
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
    
    func didUpdateVideoQuality() {
        if courseOutlineMode == .video {
            courseVideosHeaderView?.refreshView()
        }
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
            tableView.scrollToRow(at: indexPath as IndexPath, at: UITableView.ScrollPosition.middle, animated: false)
        }
        
        if courseOutlineMode == .video {
            courseVideosHeaderView?.refreshView()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        refreshTableHeaderView(isResumeCourse: isResumeCourse)
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
        
        if courseOutlineMode == .video {
            var allCompleted: Bool
            
            if group.block.type == .Unit {
                allCompleted = group.children.allSatisfy { $0.isCompleted }
            } else {
                allCompleted = group.children.map { $0.blockID }.allSatisfy(watchedVideoBlock.contains)
            }
            
            allCompleted ? header.showCompletedBackground() : header.showNeutralBackground()
        } else {
            let allCompleted = group.children.allSatisfy { $0.isCompleted }
            allCompleted ? header.showCompletedBackground() : header.showNeutralBackground()
        }
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        delegate?.outlineTableController(controller: self, choseBlock: chosenBlock, parent: group.block.blockID)
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
    
    private func resumeCourse(with item: ResumeCourseItem) {
        delegate?.outlineTableController(controller: self, resumeCourse: item)
        environment.analytics.trackResumeCourseTapped(courseID: courseID, blockID: item.lastVisitedBlockID)
    }
    
    /// Shows the last accessed Header from the item as argument. Also, sets the relevant action if the course block exists in the course outline.
    func showResumeCourse(item: ResumeCourseItem) {
        if !item.lastVisitedBlockID.isEmpty {
            courseQuerier.blockWithID(id: item.lastVisitedBlockID).extendLifetimeUntilFirstResult (success: { [weak self] block in
                self?.resumeCourseView.subtitleText = block.displayName
                self?.resumeCourseView.setViewButtonAction { [weak self] _ in
                    self?.resumeCourse(with: item)
                }
                self?.refreshTableHeaderView(isResumeCourse: true)
            }, failure: { [weak self] _ in
                self?.refreshTableHeaderView(isResumeCourse: false)
            })
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
        courseDateBannerView.bannerInfo = bannerInfo
        updateCourseDateBannerView(show: true)
    }
    
    func hideCourseDateBanner() {
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
        tableView.setAndLayoutTableHeaderView(header: headerContainer)
    }
    
    private func refreshTableHeaderView(isResumeCourse: Bool) {
        self.isResumeCourse = isResumeCourse
        resumeCourseView.isHidden = !isResumeCourse
        
        switch courseOutlineMode {
        case .full:
            if shouldHideTableViewHeader { return }
            updateHeaderConstraints()
            break
        case .video:
            if let course = environment.interface?.enrollmentForCourse(withID: courseID)?.course, courseBlockID == nil {
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
    
    deinit {
        courseQuerier.remove(observer: self)
        NotificationCenter.default.removeObserver(self)
    }
}

extension CourseOutlineTableController: CourseShiftDatesDelegate {
    func courseShiftDateButtonAction() {
        delegate?.resetCourseDate(controller: self)
    }
}

extension CourseOutlineTableController: BlockCompletionDelegate {
    func didCompletionChanged(in blockGroup: CourseOutlineQuerier.BlockGroup, mode: CourseOutlineMode) {
        
        if mode != courseOutlineMode { return }
        
        guard let index = groups.firstIndex(where: {
            return $0.block.blockID == blockGroup.block.blockID
        }) else { return }
        
        if tableView.isValidSection(with: index) {
            if mode == .full {
                groups[index] = blockGroup
            }
            tableView.reloadSections([index], with: .none)
        }
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

