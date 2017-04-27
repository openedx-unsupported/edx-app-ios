//
//  CourseDashboardViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol CourseDashboardItem {
    var identifier: String { get }
    var action:(() -> Void) { get }
    var height: CGFloat { get }

    func decorateCell(cell: UITableViewCell)
}

struct StandardCourseDashboardItem : CourseDashboardItem {
    let identifier = CourseDashboardCell.identifier
    let height:CGFloat = 85.0

    let title: String
    let detail: String
    let icon : Icon
    let action:(() -> Void)
    

    typealias CellType = CourseDashboardCell
    func decorateCell(cell: UITableViewCell) {
        guard let dashboardCell = cell as? CourseDashboardCell else { return }
        dashboardCell.useItem(item: self)
    }
}

struct CertificateDashboardItem: CourseDashboardItem {
    let identifier = CourseCertificateCell.identifier
    let height: CGFloat = 116.0

    let certificateImage: UIImage
    let certificateUrl: String
    let action:(() -> Void)

    func decorateCell(cell: UITableViewCell) {
        guard let certificateCell = cell as? CourseCertificateCell else { return }
        certificateCell.useItem(item: self)
    }
}

public class CourseDashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider
    
    private let spacerHeight: CGFloat = OEXStyles.dividerSize()

    private let environment: Environment
    private let courseID: String
    
    private let courseCard = CourseCardView(frame: CGRect.zero)
    
    private let tableView: UITableView = UITableView()
    private let stackView: TZStackView = TZStackView()
    private let containerView: UIScrollView = UIScrollView()
    private let shareButton = UIButton(type: .system)
    
    fileprivate var cellItems: [CourseDashboardItem] = []
    
    fileprivate let loadController = LoadStateViewController()
    fileprivate let courseStream = BackedStream<UserCourseEnrollment>()
    
    private lazy var progressController : ProgressController = {
        ProgressController(owner: self, router: self.environment.router, dataInterface: self.environment.interface)
    }()
    
    public init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        
        super.init(nibName: nil, bundle: nil)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.shared().neutralXLight()
        
        self.navigationItem.rightBarButtonItem = self.progressController.navigationItem()
        
        self.view.addSubview(containerView)
        self.containerView.addSubview(stackView)
        tableView.isScrollEnabled = false
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        self.view.addSubview(tableView)
        
        stackView.snp_makeConstraints { make -> Void in
            make.top.equalTo(containerView)
            make.trailing.equalTo(containerView)
            make.leading.equalTo(containerView)
        }
        stackView.alignment = .fill
        
        containerView.snp_makeConstraints {make in
            make.edges.equalTo(view)
        }
        
        addShareButton(courseView: courseCard)

        // Register tableViewCell
        tableView.register(CourseDashboardCell.self, forCellReuseIdentifier: CourseDashboardCell.identifier)
        tableView.register(CourseCertificateCell.self, forCellReuseIdentifier: CourseCertificateCell.identifier)
        
        stackView.axis = .vertical
        
        let spacer = UIView()
        stackView.addArrangedSubview(courseCard)
        stackView.addArrangedSubview(spacer)
        stackView.addArrangedSubview(tableView)
        
        spacer.snp_makeConstraints {make in
            make.height.equalTo(spacerHeight)
            make.width.equalTo(self.containerView)
        }
        
        loadController.setupInController(controller: self, contentView: containerView)
        
        self.progressController.hideProgessView()
        
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID: courseID))
        courseStream.listen(self) {[weak self] in
            self?.resultLoaded(result: $0)
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: EnrollmentShared.successNotification) { (notification, observer, _) in
            if let message = notification.object as? String {
                observer.showOverlay(withMessage: message)
            }
        }
    }
    
    private func resultLoaded(result : Result<UserCourseEnrollment>) {
        switch result {
        case let Result.success(enrollment): self.loadedCourseWithEnrollment(enrollment: enrollment)
        case let Result.failure(error):
            if !courseStream.active {
                // enrollment list is cached locally, so if the stream is still active we may yet load the course
                // don't show failure until the stream is done
                self.loadController.state = LoadState.failed(error: error)
            }
        }

    }
    
    private func loadedCourseWithEnrollment(enrollment: UserCourseEnrollment) {
        navigationItem.title = enrollment.course.name
        CourseCardViewModel.onDashboard(course: enrollment.course).apply(card: courseCard, networkManager: self.environment.networkManager)
        verifyAccessForCourse(course: enrollment.course)
        prepareTableViewData(enrollment: enrollment)
        self.tableView.reloadData()
        shareButton.isHidden = enrollment.course.course_about == nil || !environment.config.courseSharingEnabled
        shareButton.oex_removeAllActions()
        shareButton.oex_addAction({[weak self] _ in
            self?.shareCourse(course: enrollment.course)
            }, for: .touchUpInside)
    }
    
    private func shareCourse(course: OEXCourse) {
        if let urlString = course.course_about, let url = NSURL(string: urlString) {
            let analytics = environment.analytics
            let courseID = self.courseID
            let controller = shareHashtaggedTextAndALink(textBuilder: { hashtagOrPlatform in
                Strings.shareACourse(platformName: hashtagOrPlatform)
                }, url: url, analyticsCallback: { analyticsType in
                analytics.trackCourseShared(courseID, url: urlString, socialTarget: analyticsType)
            })
            self.present(controller, animated: true, completion: nil)
        }
    }

    private func addShareButton(courseView: CourseCardView) {
        if environment.config.courseSharingEnabled {
            shareButton.setImage(UIImage(named: "shareCourse.png"), for: .normal)
            shareButton.tintColor = OEXStyles.shared().neutralDark()
            courseView.titleAccessoryView = shareButton
            shareButton.snp_makeConstraints(closure: { (make) -> Void in
                make.height.equalTo(26)
                make.width.equalTo(26)
            })
        }
    }

    private func verifyAccessForCourse(course: OEXCourse) {
        if let access = course.courseware_access, !access.has_access {
            loadController.state = LoadState.failed(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info), icon: Icon.UnknownError)
        }
        else {
            loadController.state = .Loaded
        }

    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenCourseDashboard, courseID: courseID, value: nil)
        
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    public func prepareTableViewData(enrollment: UserCourseEnrollment) {
        cellItems = []
        
        if let certificateUrl = getCertificateUrl(enrollment: enrollment) {
            let item = CertificateDashboardItem(certificateImage: UIImage(named: "courseCertificate")!, certificateUrl: certificateUrl, action: {
                let url = NSURL(string: certificateUrl)!
                self.environment.router?.showCertificate(url: url, title: enrollment.course.name, fromController: self)
            })
            cellItems.append(item)
        }

        var item = StandardCourseDashboardItem(title: Strings.courseDashboardCourseware, detail: Strings.courseDashboardCourseDetail, icon : .Courseware) {[weak self] () -> Void in
            self?.showCourseware()
        }
        cellItems.append(item)
        
        if shouldShowDiscussions(course: enrollment.course) {
            let courseID = self.courseID
            item = StandardCourseDashboardItem(title: Strings.courseDashboardDiscussion, detail: Strings.courseDashboardDiscussionDetail, icon: .Discussions) {[weak self] () -> Void in
                self?.showDiscussionsForCourseID(courseID: courseID)
            }
            cellItems.append(item)
        }
        
        if shouldShowHandouts(course: enrollment.course) {
            item = StandardCourseDashboardItem(title: Strings.courseDashboardHandouts, detail: Strings.courseDashboardHandoutsDetail, icon: .Handouts) {[weak self] () -> Void in
                self?.showHandouts()
            }
            cellItems.append(item)
        }
        
        item = StandardCourseDashboardItem(title: Strings.courseDashboardAnnouncements, detail: Strings.courseDashboardAnnouncementsDetail, icon: .Announcements) {[weak self] () -> Void in
            self?.showAnnouncements()
        }
        cellItems.append(item)
    }
    
    
    private func shouldShowDiscussions(course: OEXCourse) -> Bool {
        let canShowDiscussions = self.environment.config.discussionsEnabled 
        let courseHasDiscussions = course.hasDiscussionsEnabled 
        return canShowDiscussions && courseHasDiscussions
    }
    
    private func shouldShowHandouts(course: OEXCourse) -> Bool {
        return !(course.course_handouts?.isEmpty ?? true)
    }

    private func getCertificateUrl(enrollment: UserCourseEnrollment) -> String? {
        guard environment.config.discussionsEnabled else { return nil }
        return enrollment.certificateUrl
    }
    
    
    // MARK: - TableView Data and Delegate
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellItems.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let dashboardItem = cellItems[indexPath.row]
        return dashboardItem.height
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dashboardItem = cellItems[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: dashboardItem.identifier, for: indexPath as IndexPath)
        dashboardItem.decorateCell(cell: cell)

        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dashboardItem = cellItems[indexPath.row]
        dashboardItem.action()
    }
    
    private func showCourseware() {
        self.environment.router?.showCoursewareForCourseWithID(courseID: courseID, fromController: self)
    }
    
    private func showDiscussionsForCourseID(courseID: String) {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        self.environment.router?.showDiscussionTopicsFromController(controller: self, courseID: courseID)
    }
    
    private func showHandouts() {
        self.environment.router?.showHandoutsFromController(controller: self, courseID: courseID)
    }
    
    private func showAnnouncements() {
        self.environment.router?.showAnnouncementsForCourse(withID: courseID)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.snp_updateConstraints{ make in
            make.height.equalTo(tableView.contentSize.height)
        }
        containerView.contentSize = stackView.bounds.size
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
}

// MARK: Testing
extension CourseDashboardViewController {
    
    func t_canVisitDiscussions() -> Bool {
        return self.cellItems.firstIndexMatching({ (item: CourseDashboardItem) in return (item is StandardCourseDashboardItem) && (item as! StandardCourseDashboardItem).icon == .Discussions }) != nil
    }
    
    func t_canVisitHandouts() -> Bool {
        return self.cellItems.firstIndexMatching({ (item: CourseDashboardItem) in return (item is StandardCourseDashboardItem) && (item as! StandardCourseDashboardItem).icon == .Handouts }) != nil
    }

    func t_canVisitCertificate() -> Bool {
        return self.cellItems.firstIndexMatching({ (item: CourseDashboardItem) in return (item is CertificateDashboardItem)}) != nil
    }
    
    var t_state : LoadState {
        return self.loadController.state
    }
    
    var t_loaded : OEXStream<()> {
        return self.courseStream.map {_ in () }
    }
    
}

