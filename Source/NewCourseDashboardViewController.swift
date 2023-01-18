//
//  NewCourseDashboardViewController.swift
//  edX
//
//  Created by MuhammadUmer on 18/11/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class NewCourseDashboardViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider & RemoteConfigProvider & ServerConfigProvider
    
    private lazy var headerView: CourseDashboardHeaderView = {
        let view = CourseDashboardHeaderView(environment: environment, course: course, error: courseAccessError)
        view.accessibilityIdentifier = "NewCourseDashboardViewController:header-view"
        view.delegate = self
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.accessibilityIdentifier = "NewCourseDashboardViewController:table-view"
        tableView.register(CourseDashboardErrorViewCell.self, forCellReuseIdentifier: CourseDashboardErrorViewCell.identifier)
        tableView.register(CourseDashboardAccessErrorCell.self, forCellReuseIdentifier: CourseDashboardAccessErrorCell.identifier)
        tableView.register(NewDashboardContentCell.self, forCellReuseIdentifier: NewDashboardContentCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private lazy var courseUpgradeHelper = CourseUpgradeHelper.shared
    
    private var pacing: String {
        guard let course = course else { return "" }
        return course.isSelfPaced ? "self" : "instructor"
    }
    
    private var course: OEXCourse?
    private var error: NSError?
    private var courseAccessError: CourseAccessErrorHelper?
    private var selectedTabbarItem: TabBarItem?
    
    private var isModalDismissable = true
    private let courseStream: BackedStream<UserCourseEnrollment>
    private let loadStateController: LoadStateViewController
            
    private let environment: Environment
    private let courseID: String
    private let screen: CourseUpgradeScreen = .courseDashboard
    private var coursePrice: String?
    
    init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        self.courseStream = BackedStream<UserCourseEnrollment>()
        self.loadStateController = LoadStateViewController()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubviews()
        loadCourseStream()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.setHidesBackButton(true, animated: true)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenCourseDashboard, courseID: courseID, value: nil)
    }
    
    private func addSubviews() {
        view.backgroundColor = environment.styles.neutralWhiteT()
        view.addSubview(tableView)
        
        loadStateController.setupInController(controller: self, contentView: tableView)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateViewConstraints()
    }

    override func updateViewConstraints() {
        tableView.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        configureHeaderView()
        super.updateViewConstraints()
    }
    
    private func configureHeaderView() {
        tableView.tableHeaderView = headerView
        headerView.snp.remakeConstraints { make in
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
        }
        tableView.setAndLayoutTableHeaderView(header: headerView)
    }
    
    private func loadCourseStream() {
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID: courseID))
        courseStream.listen(self) { [weak self] result in
            self?.resultLoaded(result: result)
        }
    }
    
    private func loadedCourse(withCourse course: OEXCourse) {
        verifyAccess(forCourse: course)
        configureHeaderView()
    }
    
    private func resultLoaded(result: Result<UserCourseEnrollment>) {
        switch result {
        case .success(let enrollment):
            course = enrollment.course
            loadedCourse(withCourse: enrollment.course)
        case .failure(let error):
            if !courseStream.active {
                loadStateController.state = .Loaded
                self.error = error
                headerView.showTabbarView(show: false)
                tableView.reloadData()
            }
        }
    }
    
    private func verifyAccess(forCourse course: OEXCourse) {
        self.course = course
        
        if let access = course.courseware_access, !access.has_access {
            loadStateController.state = .Loaded
            let enrollment = environment.interface?.enrollmentForCourse(withID: courseID)
            courseAccessError = CourseAccessErrorHelper(course: course, enrollment: enrollment)
            fetchCoursePrice()
            headerView.showTabbarView(show: false)
            tableView.reloadData()
        } else {
            loadStateController.state = .Loaded
            headerView.showTabbarView(show: true)
            tableView.reloadData()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    private func redirectToDiscovery() {
        dismiss(animated: true) {
            guard let rootController = UIApplication.shared.window?.rootViewController,
                  let enrolledTabbarViewController = rootController.children.first as? EnrolledTabBarViewController else { return }
            
            enrolledTabbarViewController.switchTab(with: .discovery)
        }
    }

    var showCourseAccessError: Bool {
        return courseAccessError != nil ? true : false
    }

    var showContentNotLoadedError: Bool {
        // add more logic here, like check for the content etc
        return error != nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
    
    private func fetchCoursePrice() {
        guard let courseSku = course?.sku, environment.serverConfig.iapConfig?.enabledforUser == true else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.main.async { [weak self] in
            PaymentManager.shared.productPrice(courseSku) { [weak self] price in
                if let price = price {
                    let endTime = CFAbsoluteTimeGetCurrent() - startTime
                    self?.coursePrice = price
                    self?.trackPriceLoadDuration(elapsedTime: endTime.millisecond)
                    self?.reloadCoursePriceIfNecessary()
                } else {
                    self?.trackLoadError()
                }
            }
        }
    }
    
    private func reloadCoursePriceIfNecessary() {
        if let _ = tableView.visibleCells.first(where: { $0 is CourseDashboardAccessErrorCell }) {
            tableView.reloadData()
        }
    }
}

extension NewCourseDashboardViewController: UITableViewDelegate {
    
}

extension NewCourseDashboardViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let visibleCells = tableView.visibleCells as? [NewDashboardContentCell] {
            visibleCells.forEach { cell in
                cell.viewController?.willMove(toParent: nil)
                cell.viewController?.view.removeFromSuperview()
                cell.viewController?.removeFromParent()
            }
        }
        
        if showCourseAccessError {
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseDashboardAccessErrorCell.identifier, for: indexPath) as! CourseDashboardAccessErrorCell
            
            cell.delegate = self
            cell.coursePrice = coursePrice
            if let error = courseAccessError {
                cell.handleCourseAccessError(course: course, error: error)
            }
            
            return cell
        } else if showContentNotLoadedError {
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseDashboardErrorViewCell.identifier, for: indexPath) as! CourseDashboardErrorViewCell
            cell.myCoursesAction = { [weak self] in
                self?.dismiss(animated: true)
            }
        } else if let tabBarItem = selectedTabbarItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: NewDashboardContentCell.identifier, for: indexPath) as! NewDashboardContentCell
            let contentController = tabBarItem.viewController
            addChild(contentController)
            cell.contentView.addSubview(contentController.view)
            
            let height = tableView.frame.height - headerView.frame.height
            contentController.view.snp.makeConstraints { make in
                make.edges.equalTo(cell.contentView)
                make.height.equalTo(height)
            }
            
            contentController.didMove(toParent: self)
            contentController.view.layoutIfNeeded()
            
            cell.viewController = contentController
            
            return cell
        }
        
        return UITableViewCell()
    }
}

extension NewCourseDashboardViewController: CourseDashboardHeaderViewDelegate {
    func didTapOnValueProp() {
        guard let course = course else { return }
        environment.router?.showValuePropDetailView(from: self, screen: .courseDashboard, course: course) { [weak self] in
            self?.environment.analytics.trackValuePropModal(with: .CourseDashboard, courseId: course.course_id ?? "")
        }
        environment.analytics.trackValuePropLearnMore(courseID: course.course_id ?? "", screenName: .CourseDashboard)
    }
    
    func didTapOnClose() {
        dismiss(animated: true)
    }
    
    func didTapOnShareCourse() {
        guard let course = course,
              let urlString = course.course_about,
              let url = NSURL(string: urlString) else { return }
        
        let controller = shareHashtaggedTextAndALink(textBuilder: { hashtagOrPlatform in
            Strings.shareACourse(platformName: hashtagOrPlatform)
        }, url: url, utmParams: course.courseShareUtmParams) { [weak self] analyticsType in
            self?.environment.analytics.trackCourseShared(courseID: self?.courseID ?? "", url: urlString, type: analyticsType)
        }
        
        controller.configurePresentationController(withSourceView: view)
        present(controller, animated: true, completion: nil)
    }
    
    func didTapTabbarItem(at position: Int, tabbarItem: TabBarItem) {
        if error == nil {
            selectedTabbarItem = tabbarItem
            tableView.reloadData()
        }
    }
}

extension NewCourseDashboardViewController: CourseDashboardAccessErrorCellDelegate {
    func findCourseAction() {
        redirectToDiscovery()
    }
    
    func upgradeCourseAction(course: OEXCourse, completion: @escaping ((Bool) -> ())) {
       let upgradeHandler = CourseUpgradeHandler(for: course, environment: environment)
        
        guard let courseID = course.course_id, let coursePrice = coursePrice else {
            courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .error(.generalError, nil))
            completion(false)
            return
        }
        
        environment.analytics.trackUpgradeNow(with: courseID, pacing: pacing, screenName: .courseDashboard, coursePrice: coursePrice)
        
        courseUpgradeHelper.setupHelperData(environment: environment, pacing: pacing, courseID: courseID, coursePrice: coursePrice, screen: .courseDashboard)
        
        upgradeHandler.upgradeCourse { [weak self] status in
            guard let weakSelf = self else { return }
            weakSelf.enableUserInteraction(enable: false)
            
            switch status {
            case .payment:
                weakSelf.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .payment)
                break
                
            case .verify:
                weakSelf.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .fulfillment)
                break
                
            case .complete:
                weakSelf.enableUserInteraction(enable: true)
                weakSelf.dismiss(animated: true) { [weak self] in
                    self?.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .success(course.course_id ?? "", nil))
                }
                completion(true)
                break
                
            case .error(let type, let error):
                weakSelf.enableUserInteraction(enable: true)
                weakSelf.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .error(type, error), delegate: type == .verifyReceiptError ? weakSelf : nil)
                completion(false)
                break
           
            default:
                break
            }
        }
    }
    
    private func enableUserInteraction(enable: Bool) {
        isModalDismissable = enable
        DispatchQueue.main.async { [weak self] in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enable
            self?.view.isUserInteractionEnabled = enable
        }
    }
}

extension NewCourseDashboardViewController {
    private func trackPriceLoadDuration(elapsedTime: Int) {
        guard let course = course,
              let courseID = course.course_id,
              let coursePrice = coursePrice else { return }
        
        environment.analytics.trackCourseUpgradeTimeToLoadPrice(courseID: courseID, pacing: pacing, coursePrice: coursePrice, screen: screen, elapsedTime: elapsedTime)
    }
    
    private func trackLoadError() {
        guard let course = course, let courseID = course.course_id else { return }
        environment.analytics.trackCourseUpgradeLoadError(courseID: courseID, pacing: pacing, screen: screen)
    }
}

extension NewCourseDashboardViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return isModalDismissable
    }
}

extension NewCourseDashboardViewController: CourseUpgradeHelperDelegate {
    func hideAlertAction() {
        dismiss(animated: true, completion: nil)
    }
}
