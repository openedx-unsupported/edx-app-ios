//
//  NewCourseDashboardViewController.swift
//  edX
//
//  Created by MuhammadUmer on 18/11/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

// view used at the exact same location of status bar in case of hidden navbar
let statuBarViewTag: Int = 123454321

public protocol NewCourseDashboardViewControllerDelegate: AnyObject {
    func showCourseDates(bannerInfo: DatesBannerInfo?, delegate: CourseOutlineTableController?)
    func hideCourseDates()
    func selectedController() -> UIViewController?
}

extension NewCourseDashboardViewControllerDelegate {
    public func selectedController() -> UIViewController? {
        return nil
    }
}

class NewCourseDashboardViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider & RemoteConfigProvider & ServerConfigProvider
    
    private lazy var headerView: CourseDashboardHeaderView = {
        let view = CourseDashboardHeaderView(environment: environment, course: course, tabbarItems: tabBarItems, error: courseAccessHelper)
        view.accessibilityIdentifier = "NewCourseDashboardViewController:header-view"
        view.delegate = self
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "NewCourseDashboardViewController:contentView-view"
        return view
    }()
    
    private lazy var container: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "NewCourseDashboardViewController:container-view"
        return view
    }()
    
    private lazy var courseUpgradeHelper = CourseUpgradeHelper.shared
    
    private var statusbarColor: UIColor {
        return environment.styles.primaryLightColor()
    }
    
    private var pacing: String {
        guard let course = course else { return "" }
        return course.isSelfPaced ? "self" : "instructor"
    }
    
    private var shouldShowDiscussions: Bool {
        guard let course = course else { return false }
        return environment.config.discussionsEnabled && course.hasDiscussionsEnabled
    }
    
    private var shouldShowHandouts: Bool {
        guard let course = course else { return false }
        return course.course_handouts?.isEmpty == false
    }
    
    private var course: OEXCourse?
    private var error: NSError?
    private var courseAccessHelper: CourseAccessHelper?
    private var selectedTabbarItem: TabBarItem?
    
    private var headerViewState: HeaderViewState = .expanded {
        didSet {
            headerView.state = headerViewState
        }
    }
    private var tabBarItems: [TabBarItem] = []
    private var isModalDismissable = true
    private let courseStream: BackedStream<UserCourseEnrollment>
    private let loadStateController: LoadStateViewController
            
    private let environment: Environment
    let courseID: String
    private let screen: CourseUpgradeScreen = .courseDashboard
    private let fromEnrollment: Bool
    
    init(environment: Environment, courseID: String, fromEnrollment: Bool = false) {
        self.environment = environment
        self.courseID = courseID
        self.fromEnrollment = fromEnrollment
        self.courseStream = BackedStream<UserCourseEnrollment>()
        self.loadStateController = LoadStateViewController()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        addSubviews()
        
        let delay = fromEnrollment ?  0.5 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadCourseStream()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.setHidesBackButton(true, animated: true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenCourseDashboard, courseID: courseID, value: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func addSubviews() {
        view.backgroundColor = environment.styles.neutralWhiteT()
        view.addSubview(contentView)
        contentView.snp.remakeConstraints { make in
            make.top.equalTo(view)
            make.bottom.equalTo(safeBottom)
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
        }
        setStatusBar(inside: contentView, color: statusbarColor)
        loadStateController.setupInController(controller: self, contentView: contentView)
    }
    
    private func setupConstraints() {
        container.removeFromSuperview()
        headerView.removeFromSuperview()
        
        contentView.addSubview(container)
        contentView.addSubview(headerView)
        
        headerView.snp.remakeConstraints { make in
            make.top.equalTo(safeTop)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.lessThanOrEqualTo(StandardVerticalMargin * 100)
        }
        
        container.snp.remakeConstraints { make in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalTo(contentView)
        }
    }
    
    private func loadCourseStream() {
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID: courseID))
        courseStream.listen(self) { [weak self] result in
            self?.resultLoaded(result: result)
        }
    }
    
    private func resultLoaded(result: Result<UserCourseEnrollment>) {
        switch result {
        case .success(let enrollment):
            let course = enrollment.course
            self.course = course
            prepareTabViewData()
            
            if let access = enrollment.course.courseware_access, !access.has_access {
                let enrollment = environment.interface?.enrollmentForCourse(withID: courseID)
                courseAccessHelper = CourseAccessHelper(course: course, enrollment: enrollment)
                headerView.showTabbarView(show: false)
            } else {
                headerView.showTabbarView(show: true)
            }
            
            loadStateController.state = .Loaded
            setupConstraints()
            setupContentView()
            
        case .failure(let error):
            if !courseStream.active {
                loadStateController.state = .Loaded
                self.error = error
                headerView.showTabbarView(show: false)
                setupContentView()
            }
        }
    }
    
    private func setupContentView() {
        container.subviews.forEach { $0.removeFromSuperview() }
        
        if showCourseAccessError {
            headerView.hidevalueProp()
            let view = CourseDashboardAccessErrorView()
            view.delegate = self
            view.handleCourseAccessError(environment: environment, course: course, error: courseAccessHelper)
            container.addSubview(view)
            view.snp.remakeConstraints { make in
                make.edges.equalTo(container)
            }
        } else if showContentNotLoadedError {
            headerView.hidevalueProp()
            let view = CourseDashboardErrorView()
            view.myCoursesAction = { [weak self] in
                self?.dismiss(animated: true)
            }
            container.addSubview(view)
            view.snp.remakeConstraints { make in
                make.edges.equalTo(container)
            }
        } else if let tabBarItem = selectedTabbarItem {
            headerView.hidevalueProp(hide: false)
            let contentController = tabBarItem.viewController
            if var controller = contentController as? ScrollableDelegateProvider {
                controller.scrollableDelegate = self
            }
            addChild(contentController)
            container.addSubview(contentController.view)
            contentController.view.snp.remakeConstraints { make in
                make.edges.equalTo(container)
            }
            contentController.didMove(toParent: self)
            contentController.view.layoutIfNeeded()
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
        return courseAccessHelper != nil
    }

    var showContentNotLoadedError: Bool {
        // add more logic here, like check for the content etc
        return error != nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setupContentView()
        
        coordinator.animate { [weak self] _ in
            guard let weakSelf = self else { return }
            DispatchQueue.main.async {
                weakSelf.setStatusBar(inside: weakSelf.contentView, color: weakSelf.statusbarColor)
            }
        }
        
        if headerViewState == .collapsed {
            collapseHeaderView()
        } else if headerViewState == .expanded {
            expandHeaderView()
        }
    }
    
    private func prepareTabViewData() {
        tabBarItems = []
        let outlineController = CourseOutlineViewController(environment: environment, courseID: courseID, rootID: nil, forMode: .full, newDashboardDelegate: self)
        var item = TabBarItem(title: Strings.Dashboard.courseHome, viewController: outlineController, icon: Icon.Courseware, detailText: Strings.Dashboard.courseCourseDetail)
        tabBarItems.append(item)
        
        if environment.config.isCourseVideosEnabled {
            item = TabBarItem(title: Strings.Dashboard.courseVideos, viewController: CourseOutlineViewController(environment: environment, courseID: courseID, rootID: nil, forMode: .video), icon: Icon.CourseVideos, detailText: Strings.Dashboard.courseVideosDetail)
            tabBarItems.append(item)
        }
        
        if shouldShowDiscussions {
            item = TabBarItem(title: Strings.Dashboard.courseDiscussion, viewController: DiscussionTopicsViewController(environment: environment, courseID: courseID), icon: Icon.Discussions, detailText: Strings.Dashboard.courseDiscussionDetail)
            tabBarItems.append(item)
        }
        
        if environment.config.courseDatesEnabled {
            item = TabBarItem(title: Strings.Dashboard.courseImportantDates, viewController: CourseDatesViewController(environment: environment , courseID: courseID), icon: Icon.Calendar, detailText: Strings.Dashboard.courseImportantDatesDetail)
            tabBarItems.append(item)
        }

        if shouldShowHandouts {
            item = TabBarItem(title: Strings.Dashboard.courseHandouts, viewController: CourseHandoutsViewController(environment: environment, courseID: courseID), icon: Icon.Handouts, detailText: Strings.Dashboard.courseHandoutsDetail)
            tabBarItems.append(item)
        }
        
        if environment.config.isAnnouncementsEnabled {
            item = TabBarItem(title: Strings.Dashboard.courseAnnouncements, viewController: CourseAnnouncementsViewController(environment: environment, courseID: courseID), icon:Icon.Announcements, detailText: Strings.Dashboard.courseAnnouncementsDetail)
            tabBarItems.append(item)
        }
    }
    
    func switchTab(with type: DeepLinkType, deeplink: DeepLink? = nil) {
        var selectedItem: TabBarItem?
        
        switch type {
        case .courseDashboard:
            selectedItem = tabbarViewItem(with: CourseOutlineViewController.self, courseOutlineMode: .full)
            break
        case .courseComponent:
            selectedItem = tabbarViewItem(with: CourseOutlineViewController.self, courseOutlineMode: .full)
            if let controller = selectedItem?.viewController as? CourseOutlineViewController {
                controller.componentID = deeplink?.componentID
            }
            break
        case .courseVideos:
            selectedItem = tabbarViewItem(with: CourseOutlineViewController.self, courseOutlineMode: .video)
            break
        case .discussions, .discussionTopic, .discussionPost, .discussionComment:
            selectedItem = tabbarViewItem(with: DiscussionTopicsViewController.self)
            break
        case .courseDates:
            selectedItem = tabbarViewItem(with: CourseDatesViewController.self)
            break
        case .courseHandout:
            let item = tabbarViewItem(with: CourseHandoutsViewController.self)
            selectedItem = item == nil ? tabbarViewItem(with: AdditionalTabBarViewController.self) : item
            break
        case .courseAnnouncement:
            let item = tabbarViewItem(with: CourseAnnouncementsViewController.self)
            selectedItem = item == nil ? tabbarViewItem(with: AdditionalTabBarViewController.self) : item
            break
        default:
            selectedItem = tabBarItems.first
            break
        }
        
        if let selectedItem = selectedItem {
            selectedTabbarItem?.viewController.removeFromParent()
            selectedTabbarItem = selectedItem
            headerView.updateTabbarView(item: selectedItem)
            setupContentView()
        }
    }
    
    func tabbarViewItem(with controller: AnyClass, courseOutlineMode: CourseOutlineMode? = .full) -> TabBarItem? {
        for item in tabBarItems {
            if item.viewController.isKind(of: controller) {
                if item.viewController.isKind(of: CourseOutlineViewController.self) {
                    if let courseOutlineVC = item.viewController as? CourseOutlineViewController {
                        if let courseOutlineMode = courseOutlineMode {
                            if courseOutlineVC.courseOutlineMode == courseOutlineMode {
                                return item
                            }
                        } else {
                            return item
                        }
                    }
                } else {
                    return item
                }
            }
        }
        return nil
    }
    
    var currentVisibileController: UIViewController? {
        return selectedTabbarItem?.viewController
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
    
    func didTapOnShareCourse(shareView: UIView) {
        guard let course = course,
              let urlString = course.course_about,
              let url = NSURL(string: urlString) else { return }
        
        let controller = shareHashtaggedTextAndALink(textBuilder: { hashtagOrPlatform in
            Strings.shareACourse(platformName: hashtagOrPlatform)
        }, url: url, utmParams: course.courseShareUtmParams) { [weak self] analyticsType in
            self?.environment.analytics.trackCourseShared(courseID: self?.courseID ?? "", url: urlString, type: analyticsType)
        }
        
        let location = CGRect(x: shareView.bounds.origin.x + shareView.bounds.size.width - 18, y: shareView.bounds.origin.y, width: 18, height: shareView.bounds.size.height)
        
        controller.configurePresentationController(withSourceView: shareView, location: location)
        
        present(controller, animated: true, completion: nil)
    }
    
    func didTapTabbarItem(at position: Int, tabbarItem: TabBarItem) {
        if courseAccessHelper == nil && selectedTabbarItem != tabbarItem  {
            selectedTabbarItem?.viewController.removeFromParent()
            selectedTabbarItem = tabbarItem
            setupContentView()
        }
    }
}

extension NewCourseDashboardViewController: CourseDashboardAccessErrorViewDelegate {
    func findCourseAction() {
        redirectToDiscovery()
    }
    
    func coursePrice(cell: CourseDashboardAccessErrorView, price: String?, elapsedTime: Int) {
        if let price = price {
            trackPriceLoadDuration(price: price, elapsedTime: elapsedTime)
        }
        else {
            trackPriceLoadError(cell: cell)
        }
    }
    
    func upgradeCourseAction(course: OEXCourse, coursePrice: String, price: NSDecimalNumber?, currencyCode: String?, completion: @escaping ((Bool) -> ())) {
        let upgradeHandler = CourseUpgradeHandler(for: course, environment: environment)
        
        guard let courseID = course.course_id else {
            courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .error(.generalError, nil))
            completion(false)
            return
        }
        
        environment.analytics.trackUpgradeNow(with: courseID, pacing: pacing, screenName: .courseDashboard, coursePrice: coursePrice)
        
        courseUpgradeHelper.setupHelperData(environment: environment, pacing: pacing, courseID: courseID, localizedCoursePrice: coursePrice, screen: .courseDashboard)
        
        upgradeHandler.upgradeCourse(price: price, currencyCode: currencyCode) { [weak self] status in
            guard let weakSelf = self else { return }
            weakSelf.enableUserInteraction(enable: false)
            
            switch status {
            case .payment:
                weakSelf.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .payment)
                break
                
            case .verify:
                weakSelf.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .fulfillment(showLoader: true))
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
                weakSelf.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .error(type, error), delegate: type == .verifyReceiptError ? self : nil)
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
    private func trackPriceLoadDuration(price: String, elapsedTime: Int) {
        guard let course = course,
              let courseID = course.course_id else { return }
        
        environment.analytics.trackCourseUpgradeTimeToLoadPrice(courseID: courseID, pacing: pacing, coursePrice: price, screen: screen, elapsedTime: elapsedTime)
    }
    
    private func trackPriceLoadError(cell: CourseDashboardAccessErrorView) {
        guard let course = course, let courseID = course.course_id else { return }
        environment.analytics.trackCourseUpgradeLoadError(courseID: courseID, pacing: pacing, screen: screen)
        showCoursePriceErrorAlert(cell: cell)
    }
    
    private func showCoursePriceErrorAlert(cell: CourseDashboardAccessErrorView) {
        guard let topController = UIApplication.shared.topMostController() else { return }

        let alertController = UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.FailureAlert.alertTitle, message: Strings.CourseUpgrade.FailureAlert.priceFetchErrorMessage, cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }


        alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.priceFetchError) { [weak self] _ in
            cell.fetchCoursePrice()
            self?.environment.analytics.trackCourseUpgradeErrorAction(courseID: self?.course?.course_id ?? "" , blockID: "", pacing: self?.pacing ?? "", coursePrice: "", screen: self?.screen ?? .none, errorAction: CourseUpgradeHelper.ErrorAction.reloadPrice.rawValue, upgradeError: "price", flowType: CourseUpgradeHandler.CourseUpgradeMode.userInitiated.rawValue)
        }

        alertController.addButton(withTitle: Strings.cancel, style: .default) { [weak self] _ in
            cell.hideUpgradeButton()
            self?.environment.analytics.trackCourseUpgradeErrorAction(courseID: self?.course?.course_id ?? "" , blockID: "", pacing: self?.pacing ?? "", coursePrice: "", screen: self?.screen ?? .none, errorAction: CourseUpgradeHelper.ErrorAction.close.rawValue, upgradeError: "price", flowType: CourseUpgradeHandler.CourseUpgradeMode.userInitiated.rawValue)
        }
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

extension NewCourseDashboardViewController: ScrollableDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard headerViewState != .animating else { return }
        
        if scrollView.contentOffset.y <= 0 {
            if headerViewState == .collapsed {
                headerViewState = .animating
                expandHeaderView()
            }
        } else if headerViewState == .expanded {
            headerViewState = .animating
            collapseHeaderView()
        }
    }
}

extension NewCourseDashboardViewController {
    private func expandHeaderView() {
        headerView.snp.remakeConstraints { make in
            make.top.equalTo(safeTop)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.lessThanOrEqualTo(StandardVerticalMargin * 60)
        }
        
        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: .calculationModeLinear) { [weak self] in
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                self?.headerView.updateTabbarConstraints(collapse: false)
                self?.headerView.showCourseTitleHeaderLabel(show: false)
                self?.view.layoutIfNeeded()
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self?.headerView.updateHeader(collapse: false)
            }
        } completion: { [weak self] _ in
            self?.headerViewState = .expanded
        }
    }
    
    private func collapseHeaderView() {
        headerView.updateHeader(collapse: true)
        
        headerView.snp.remakeConstraints { make in
            make.top.equalTo(safeTop)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(StandardVerticalMargin * 11)
        }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.headerView.showCourseTitleHeaderLabel(show: true)
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.headerViewState = .collapsed
        }
    }
}

extension NewCourseDashboardViewController: NewCourseDashboardViewControllerDelegate {
    func showCourseDates(bannerInfo: DatesBannerInfo?, delegate: CourseOutlineTableController?) {
        headerView.showDatesBanner(delegate: delegate, bannerInfo: bannerInfo)
    }
    
    func hideCourseDates() {
        headerView.removeDatesBanner()
    }
    
    func selectedController() -> UIViewController? {
        return selectedTabbarItem?.viewController
    }
}

public extension UIViewController {
    func setStatusBar(inside contentView: UIView? = nil, color: UIColor) {
        let overView: UIView
        
        if let contentView = contentView, let taggedView = contentView.viewWithTag(statuBarViewTag) {
            overView = taggedView
        } else if contentView != nil {
            overView = UIView()
            overView.tag = statuBarViewTag
            contentView?.addSubview(overView)
        } else if let taggedView = view.viewWithTag(statuBarViewTag) {
            overView = taggedView
        } else {
            overView = UIView()
            overView.tag = statuBarViewTag
            view.addSubview(overView)
        }
        
        let height = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        let frame = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
        overView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: height)
        overView.backgroundColor = color
    }
}
