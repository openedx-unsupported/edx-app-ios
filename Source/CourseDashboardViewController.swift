//
//  CourseDashboardViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class CourseDashboardViewControllerEnvironment : NSObject {
    private let analytics : OEXAnalytics?
    private let config: OEXConfig?
    private let networkManager : NetworkManager?
    private weak var router: OEXRouter?
    
    public init(analytics : OEXAnalytics?, config: OEXConfig?, networkManager: NetworkManager?, router: OEXRouter?) {
        self.analytics = analytics
        self.config = config
        self.networkManager = networkManager
        self.router = router
    }
}

struct CourseDashboardItem {
    let title: String
    let detail: String
    let icon : Icon
    let action:(() -> Void)
}

public class CourseDashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    private let cellHeight: CGFloat = 85
    private let spacerHeight: CGFloat = OEXStyles.dividerSize()

    private let environment: CourseDashboardViewControllerEnvironment
    private let course: OEXCourse?
    
    private let tableView: UITableView = UITableView()
    private let stackView: TZStackView = TZStackView()
    private let containerView: UIScrollView = UIScrollView()
    
    private var cellItems: [CourseDashboardItem] = []
    
    private let loadController = LoadStateViewController()
    
    public init(environment: CourseDashboardViewControllerEnvironment, course: OEXCourse?) {
        self.environment = environment
        self.course = course
        
        super.init(nibName: nil, bundle: nil)
        
        navigationItem.title = course?.name
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        self.view.addSubview(containerView)
        self.containerView.addSubview(stackView)
        tableView.scrollEnabled = false
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clearColor()
        self.view.addSubview(tableView)
        
        stackView.snp_makeConstraints { make -> Void in
            make.top.equalTo(containerView)
            make.trailing.equalTo(containerView)
            make.leading.equalTo(containerView)
        }
        stackView.alignment = .Fill
        
        containerView.snp_makeConstraints {make in
            make.edges.equalTo(view)
        }
        
        let courseView = CourseCardView(frame: CGRectZero)
        if let course = self.course {
            CourseCardViewModel.applyCourse(course, toCardView: courseView, forType : .Dashboard)
        }
        
        // Register tableViewCell
        tableView.registerClass(CourseDashboardCell.self, forCellReuseIdentifier: CourseDashboardCell.identifier)
        
        prepareTableViewData()
        
        stackView.axis = .Vertical
        
        let spacer = UIView()
        stackView.addArrangedSubview(courseView)
        stackView.addArrangedSubview(spacer)
        stackView.addArrangedSubview(tableView)
        
        spacer.snp_makeConstraints {make in
            make.height.equalTo(spacerHeight)
            make.width.equalTo(self.containerView)
        }
        
        verifyAccess()
    }
    
    private func verifyAccess() {
        loadController.setupInController(self, contentView: containerView)
        
        guard let course = course else {
            loadController.state = LoadState.failed()
            return
        }
        
        if let access = course.courseware_access where !access.has_access {
            loadController.state = LoadState.failed(OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info), icon: Icon.UnknownError)
        }
        else {
            loadController.state = .Loaded
        }

    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics?.trackScreenWithName(OEXAnalyticsScreenCourseDashboard, courseID: self.course?.course_id, value: nil)
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    public func prepareTableViewData() {
        var item = CourseDashboardItem(title: Strings.courseDashboardCourseware, detail: Strings.courseDashboardCourseDetail, icon : .Courseware) {[weak self] () -> Void in
            self?.showCourseware()
        }
        cellItems.append(item)
        
        if let courseID = course?.course_id where shouldShowDiscussions() {
            item = CourseDashboardItem(title: Strings.courseDashboardDiscussion, detail: Strings.courseDashboardDiscussionDetail, icon: .Discussions) {[weak self] () -> Void in
                self?.showDiscussionsForCourseID(courseID)
            }
            cellItems.append(item)
        }
        
        item = CourseDashboardItem(title: Strings.courseDashboardHandouts, detail: Strings.courseDashboardHandoutsDetail, icon: .Handouts) {[weak self] () -> Void in
            self?.showHandouts()
        }
        cellItems.append(item)
        
        item = CourseDashboardItem(title: Strings.courseDashboardAnnouncements, detail: Strings.courseDashboardAnnouncementsDetail, icon: .Announcements) {[weak self] () -> Void in
            self?.showAnnouncements()
        }
        cellItems.append(item)
    }
    
    
    private func shouldShowDiscussions() -> Bool {
        let canShowDiscussions = self.environment.config?.shouldEnableDiscussions() ?? false
        let courseHasDiscussions = course?.hasDiscussionsEnabled ?? false
        return canShowDiscussions && courseHasDiscussions
    }
    
    
    // MARK: - TableView Data and Delegate
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellItems.count
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeight
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CourseDashboardCell.identifier, forIndexPath: indexPath) as! CourseDashboardCell
        
        let dashboardItem = cellItems[indexPath.row]
        cell.useItem(dashboardItem)
        
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let dashboardItem = cellItems[indexPath.row]
        dashboardItem.action()
    }
    
    private func showCourseware() {
        if let course = self.course, courseID = course.course_id {
            self.environment.router?.showCoursewareForCourseWithID(courseID, fromController: self)
        }
    }
    
    private func showDiscussionsForCourseID(courseID: String) {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        self.environment.router?.showDiscussionTopicsFromController(self, courseID: courseID)
    }
    
    private func showHandouts() {
        if let course = self.course, courseID = course.course_id {
            self.environment.router?.showHandoutsFromController(self, courseID: courseID)
        }
    }
    
    private func showAnnouncements() {
        self.environment.router?.showAnnouncementsForCourseWithID(course?.course_id)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.snp_updateConstraints{ make in
            make.height.equalTo(CGFloat(cellItems.count) * cellHeight)
        }
        containerView.contentSize = stackView.bounds.size
    }
}

// MARK: Testing
extension CourseDashboardViewController {
    
    internal func t_canVisitDiscussions() -> Bool {
        return self.cellItems.firstIndexMatching({ (item: CourseDashboardItem) in return item.icon == .Discussions }) != nil
    }
    
    internal var t_state : LoadState {
        return self.loadController.state
    }
    
}

