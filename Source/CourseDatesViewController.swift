//
//  CourseDatesViewController.swift
//  edX
//
//  Created by Salman on 08/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import WebKit

class CourseDatesViewController: UIViewController, InterfaceOrientationOverriding, ScrollViewControllerDelegateProvider {
    
    private enum Pacing: String {
        case user = "self"
        case instructor
    }
    
    private enum SyncReason: String {
        case direct = "in_app"
        case background = "out_of_app"
    }
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & ReachabilityProvider & NetworkManagerProvider & OEXRouterProvider & DataManagerProvider & OEXInterfaceProvider & RemoteConfigProvider
    
    private let datesLoader = BackedStream<(CourseDateModel, UserPreference?)>()
    private let courseDateBannerLoader = BackedStream<(CourseDateBannerModel)>()
    private var stream: OEXStream<(CourseDateModel, UserPreference?)>?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableHeaderView = courseDatesHeaderView
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(CourseDateViewCell.self, forCellReuseIdentifier: CourseDateViewCell.identifier)
        
        return tableView
    }()
    
    private lazy var refreshController: PullRefreshController = {
        let refreshController = PullRefreshController()
        refreshController.delegate = self
        return refreshController
    }()
    
    private lazy var loadController = LoadStateViewController()
    
    private lazy var courseDatesHeaderView: CourseDatesHeaderView = {
        let view = CourseDatesHeaderView(frame: .zero)
        view.accessibilityIdentifier = "CourseDatesViewController:CourseDatesHeaderView"
        view.syncState = calendarState
        view.delegate = self
        return view
    }()
        
    private var calendarSyncConfig: CalendarSyncConfig {
        return environment.remoteConfig.calendarSyncConfig
    }
    
    private lazy var courseQuerier: CourseOutlineQuerier = {
        return environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
    }()
    
    private var courseDateModel: CourseDateModel?
    private var dateBlocks: [Date : [CourseDateBlock]] = [:]
    private var dateBlocksMapSortedKeys: [Date] = []
    private var isDueNextSet = false
    private var dueNextCellIndex: Int?
    private var datesShifted = false
    
    private let courseID: String
    private let environment: Environment
    
    private lazy var platformName: String = {
        return environment.config.platformName()
    }()
    
    private lazy var calendar: CalendarManager = {
        return CalendarManager(courseID: courseID, courseName: course?.name ?? platformName, courseQuerier: courseQuerier)
    }()
    
    private var course: OEXCourse? {
        return environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.course
    }
    
    private var isSelfPaced: Bool {
        return course?.isSelfPaced ?? false
    }
    
    private var calendarSyncEnabled: Bool {
        return isSelfPaced ? calendarSyncConfig.selfPacedEnabled : calendarSyncConfig.instructorPacedEnabled
    }
    
    private var userEnrollment: EnrollmentMode {
        return environment.interface?.enrollmentForCourse(withID: courseID)?.type ?? .none
    }
    
    private var calendarState: Bool {
        set {
            if newValue {
                trackCalendarEvent(for: .CalendarToggleOn, eventName: .CalendarToggleOn)
                handleCalendar()
            } else {
                trackCalendarEvent(for: .CalendarToggleOff, eventName: .CalendarToggleOff)
                showAlertForRemoveCalendarPrompt()
            }
        }
        get {
            return calendar.syncOn
        }
    }
    
    private var courseBanner: CourseDateBannerModel?
    
    weak var scrollViewDelegate: ScrollableViewControllerDelegate?
    
    init(environment: Environment, courseID: String) {
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
        
        setupView()
        setConstraints()
        setAccessibilityIdentifiers()
        loadStreams()
        addObservers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: AnalyticsScreenName.CourseDates.rawValue, courseID: courseID, value: nil)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func loadStreams(fromPullToRefresh: Bool = false) {
        if !fromPullToRefresh {
            loadController.state = .Initial
        }
        loadCourseDates()
        loadCourseBannerStream()
    }
    
    private func addObservers() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_SHIFT_COURSE_DATES) { _, observer, _ in
            observer.datesShifted = true
            observer.loadStreams()
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_FIREBASE_REMOTE_CONFIG) { _, observer, _ in
            DispatchQueue.main.async {
                observer.updateHeaderView()
            }
        }
    }
    
    private func setupView() {
        view.backgroundColor = environment.styles.standardBackgroundColor()
        view.addSubview(tableView)
        navigationItem.title = Strings.Coursedates.courseImportantDatesTitle
        loadController.setupInController(controller: self, contentView: tableView)
        refreshController.setupInScrollView(scrollView: tableView)
    }
    
    private func loadCourseDates() {
        let preferenceStream = environment.dataManager.userPreferenceManager.feed.output
        let networkRequest = CourseDatesAPI.courseDatesRequest(courseID: courseID)
        let datesStream = environment.networkManager.streamForRequest(networkRequest)
        stream = joinStreams(datesStream, preferenceStream)
        datesLoader.addBackingStream(datesLoader)
        
        stream?.listen(self) { [weak self] response in
            self?.refreshController.endRefreshing()
            switch response {
            case .success((var courseDateModel, let userPreference)):
                if courseDateModel.dateBlocks.isEmpty {
                    self?.loadController.state = .failed(message: Strings.Coursedates.courseDateUnavailable)
                } else {
                    courseDateModel.defaultTimeZone = userPreference?.timeZone
                    self?.populate(with: courseDateModel)
                    self?.loadController.state = .Loaded
                    self?.addCourseEventsIfNecessary()
                }
                break
                
            case .failure(let error):
                self?.loadController.state = .failed(message: error.localizedDescription)
                break
            }
        }
    }
    
    private func loadCourseBannerStream() {
        let courseBannerRequest = CourseDateBannerAPI.courseDateBannerRequest(courseID: courseID)
        let courseBannerStream = environment.networkManager.streamForRequest(courseBannerRequest)
        courseDateBannerLoader.backWithStream(courseBannerStream)
        
        courseBannerStream.listen(self) { [weak self] result in
            switch result {
            case .success(let courseBanner):
                self?.courseBanner = courseBanner
                self?.updateHeaderView()
                break
                
            case .failure(let error):
                Logger.logError("DatesResetBanner", "Unable to load dates reset banner: \(error.localizedDescription)")
                break
            }
        }
    }
    
    private func updateHeaderView() {
        guard let courseBanner = courseBanner else { return }
        loadCourseDateHeaderView(bannerModel: courseBanner, calendarSyncEnabled: calendarSyncEnabled)
    }
    
    private func loadCourseDateHeaderView(bannerModel: CourseDateBannerModel, calendarSyncEnabled: Bool) {
        if bannerModel.hasEnded {
            updateCourseHeaderVisibility(visibile: false)
        } else {
            trackDateBannerAppearanceEvent(bannerModel: bannerModel)
            courseDatesHeaderView.setupView(with: bannerModel.bannerInfo, isSelfPaced: isSelfPaced, calendarSyncEnabled: calendarSyncEnabled)
            updateCourseHeaderVisibility(visibile: true)
            tableView.setAndLayoutTableHeaderView(header: courseDatesHeaderView)
        }
    }
    
    private func updateCourseHeaderVisibility(visibile: Bool) {
        courseDatesHeaderView.isHidden = !true
        courseDatesHeaderView.snp.remakeConstraints { make in
            make.leading.equalTo(safeLeading).offset(StandardHorizontalMargin)
            make.trailing.equalTo(safeTrailing).inset(StandardHorizontalMargin)
            make.top.equalTo(tableView).offset(StandardVerticalMargin)
            if !visibile {
                make.height.equalTo(0)
            }
        }
    }
    
    private func populate(with dateModel: CourseDateModel) {
        courseDateModel = dateModel
        var blocks = dateModel.dateBlocks
        
        dateBlocks = [:]
        
        let isToday = blocks.first { $0.isToday }
        
        if isToday == nil {
            let past = blocks.filter { $0.isInPast }
            let future = blocks.filter { $0.isInFuture }
            let todayBlock = CourseDateBlock()
            
            blocks.removeAll()
            
            blocks.append(contentsOf: past)
            blocks.append(todayBlock)
            blocks.append(contentsOf: future)
        }
                
        for block in blocks {
            let key = block.blockDate
            if dateBlocks.keys.contains(key) {
                if var item = dateBlocks[key] {
                    item.append(block)
                    dateBlocks[key] = item
                }
            } else {
                dateBlocks[key] = [block]
            }
        }
                
        dateBlocksMapSortedKeys = dateBlocks.keys.sorted()
        tableView.reloadData()
    }
    
    private func setAccessibilityIdentifiers() {
        view.accessibilityIdentifier = "CourseDatesViewController:view"
        tableView.accessibilityIdentifier = "CourseDatesViewController:table-view"
    }
    
    private func setConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    private func resetCourseDate() {
        trackDatesShiftTapped()
        
        let request = CourseDateBannerAPI.courseDatesResetRequest(courseID: courseID)
        environment.networkManager.taskForRequest(request) { [weak self] result  in
            if let _ = result.error {
                self?.trackDatesShiftEvent(success: false)
                self?.showBottomActionSnackBar(message: Strings.Coursedates.ResetDate.errorMessage)
            } else {
                self?.trackDatesShiftEvent(success: true)
                self?.showBottomActionSnackBar(message: Strings.Coursedates.ResetDate.successMessage)
                self?.postCourseDateResetNotification()
            }
        }
    }
    
    private func trackDateBannerAppearanceEvent(bannerModel: CourseDateBannerModel) {
        guard let eventName = bannerModel.bannerInfo.status?.analyticsEventName,
              let bannerType = bannerModel.bannerInfo.status?.analyticsBannerType,
              let courseMode = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.mode else { return }
        environment.analytics.trackDatesBannerAppearence(screenName: AnalyticsScreenName.DatesScreen, courseMode: courseMode, eventName: eventName, bannerType: bannerType)
    }
    
    private func trackDatesShiftTapped() {
        guard let courseMode = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.mode else { return }
        environment.analytics.trackDatesShiftButtonTapped(screenName: AnalyticsScreenName.DatesScreen, courseMode: courseMode)
    }
    
    private func trackDatesShiftEvent(success: Bool) {
        guard let courseMode = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.mode else { return }
        environment.analytics.trackDatesShiftEvent(screenName: AnalyticsScreenName.DatesScreen, courseMode: courseMode, success: success)
    }
    
    private func postCourseDateResetNotification() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NOTIFICATION_SHIFT_COURSE_DATES)))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension CourseDatesViewController {
    private func handleCalendar() {
        calendar.requestAccess { [weak self] _, previousStatus, status in
            switch status {
            case .authorized:
                if previousStatus == .notDetermined {
                    self?.trackCalendarEvent(for: .CalendarAccessAllowed, eventName: .CalendarAccessAllowed)
                }
                self?.showAlertForAddCalendarPrompt()
                break
            default:
                if previousStatus == .notDetermined {
                    self?.trackCalendarEvent(for: .CalendarAccessDontAllow, eventName: .CalendarAccessDontAllow)
                }
                self?.courseDatesHeaderView.syncState = false
                if previousStatus == status {
                    self?.showCalendarSettingsAlert()
                }
                break
            }
        }
    }
    
    private func showCalendarSettingsAlert() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        let message = Strings.Coursedates.calendarPermissionNotDetermined(platformName: platformName)
        let alertController = UIAlertController().showAlert(withTitle: Strings.settings, message: message, cancelButtonTitle: Strings.cancel, onViewController: self) { [weak self] alertController, _, index in
            if index == alertController.cancelButtonIndex {
                self?.courseDatesHeaderView.syncState = false
            }
        }
        
        alertController.addButton(withTitle: Strings.Coursedates.openSettings) { _ in
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func addCourseEventsIfNecessary() {
        guard calendarSyncEnabled else { return }
        
        DispatchQueue.global().async { [weak self] in
            guard let weakSelf = self else { return }
            if weakSelf.calendar.syncOn && weakSelf.calendar.checkIfEventsShouldBeShifted(for: weakSelf.dateBlocks) {
                DispatchQueue.main.async { [weak self] in
                    self?.showCalendarEventShiftAlert()
                }
            }
        }
    }
    
    private func showCalendarEventShiftAlert() {
        guard let topController = UIApplication.shared.topMostController() else { return }
        
        let alertController = UIAlertController().showAlert(withTitle: Strings.Coursedates.calendarOutOfDate, message: Strings.Coursedates.calendarShiftMessage, cancelButtonTitle: nil, onViewController: topController)
        
        alertController.addButton(withTitle: Strings.Coursedates.calendarShiftPromptUpdateNow) { [weak self] _ in
            self?.trackCalendarEvent(for: .CalendarSyncUpdateDates, eventName: .CalendarSyncUpdateDates)
            self?.removeCourseCalendar(trackAnalytics: false) { _ in
                self?.addCourseEvents(trackAnalytics: false) { success in
                    if success {
                        topController.showBottomActionSnackBar(message: Strings.Coursedates.calendarEventsUpdated)
                        let syncReason: SyncReason = self?.datesShifted ?? false ? .direct : .background
                        self?.datesShifted = false
                        self?.trackCalendarEvent(for: .CalendarUpdateDatesSuccess, eventName: .CalendarUpdateDatesSuccess, syncReason: syncReason)
                    }
                }
            }
        }
        
        alertController.addButton(withTitle: Strings.Coursedates.calendarShiftPromptRemoveCourseCalendar, style: .destructive) { [weak self] _ in
            self?.trackCalendarEvent(for: .CalendarSyncRemoveCalendar, eventName: .CalendarSyncRemoveCalendar)
            self?.removeCourseCalendar { success in
                if success {
                    topController.showBottomActionSnackBar(message: Strings.Coursedates.calendarEventsRemoved)
                }
            }
        }
    }
    
    private func addCourseEvents(trackAnalytics: Bool = true, completion: ((Bool) -> ())? = nil) {
        guard let topController = UIApplication.shared.topMostController() else { return }
        
        var alertController: UIAlertController?
        var calendarOperationHandled = false
        var calendarEventsAdded = false
        let startTime = CFAbsoluteTimeGetCurrent()
        var endTime: CFTimeInterval?
        
        func updateCalendarState() {
            if calendarEventsAdded {
                if trackAnalytics {
                    trackCalendarEvent(for: .CalendarAddDatesSuccess, eventName: .CalendarAddDatesSuccess, elapsedTime: endTime?.millisecond ?? 0)
                }
                calendar.syncOn = calendarEventsAdded
                eventsAddedSuccessAlert()
            }
            courseDatesHeaderView.syncState = calendarEventsAdded
            completion?(calendarEventsAdded)
        }
        
        let presentationCompletion = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.calendar.addEventsToCalendar(for: weakSelf.dateBlocks) { success in
                endTime = CFAbsoluteTimeGetCurrent() - startTime
                calendarOperationHandled = true
                calendarEventsAdded = success
            }
        }
        
        alertController = UIAlertController().showProgressDialogAlert(viewController: topController, message: Strings.Coursedates.calendarSyncMessage, completion: presentationCompletion)
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if calendarOperationHandled {
                timer.invalidate()
                alertController?.dismiss(animated: true) {
                    updateCalendarState()
                }
            }
        }
    }
    
    private func removeCourseCalendar(trackAnalytics: Bool = true, completion: ((Bool)->())? = nil) {
        calendar.removeCalendar { [weak self] success in
            if success && trackAnalytics {
                self?.trackCalendarEvent(for: .CalendarRemoveDatesSuccess, eventName: .CalendarRemoveDatesSuccess)
            }
            self?.courseDatesHeaderView.syncState = !success
            completion?(success)
        }
    }
    
    private func showAlertForAddCalendarPrompt() {
        let title = Strings.Coursedates.addCalendarTitle(calendarName: calendar.calendarName)
        let message = Strings.Coursedates.addCalendarPrompt(platformName: platformName, calendarName: calendar.calendarName)
        
        let alertController = UIAlertController().showAlert(withTitle: title, message: message, cancelButtonTitle: Strings.cancel, onViewController: self) { [weak self] alertController, _, index in
            
            if index == alertController.cancelButtonIndex {
                self?.courseDatesHeaderView.syncState = false
                self?.calendar.syncOn = false
                self?.removeCourseCalendar()
                self?.trackCalendarEvent(for: .CalendarAddCancelled, eventName: .CalendarAddCancelled)
            }
        }
        
        alertController.addButton(withTitle: Strings.add) { [weak self] _ in
            self?.trackCalendarEvent(for: .CalendarAddDates, eventName: .CalendarAddDates)
            self?.addCourseEvents()
        }
    }
    
    private func showAlertForRemoveCalendarPrompt() {
        let title = Strings.Coursedates.removeCalendarTitle(calendarName: calendar.calendarName)
        let message = Strings.Coursedates.removeCalendarPrompt(platformName: platformName, calendarName: calendar.calendarName)
        
        let alertController = UIAlertController().showAlert(withTitle: title, message: message, cancelButtonTitle: Strings.cancel, onViewController: self) { [weak self] alertController, _, index in
            
            if index == alertController.cancelButtonIndex {
                self?.trackCalendarEvent(for: .CalendarRemoveDatesCancelled, eventName: .CalendarRemoveDatesCancelled)
                self?.courseDatesHeaderView.syncState = true
                self?.calendar.syncOn = true
            }
        }
        
        let removeAction = UIAlertAction(title: Strings.remove, style: .destructive) { [weak self] _ in
            self?.trackCalendarEvent(for: .CalendarRemoveDatesOK, eventName: .CalendarRemoveDatesOK)
            self?.removeCourseCalendar { success in
                if success {
                    self?.showBottomActionSnackBar(message: Strings.Coursedates.calendarEventsRemoved)
                }
            }
        }
        
        alertController.addAction(removeAction)
    }
    
    private func eventsAddedSuccessAlert() {
        if calendar.isModalPresented {
            showBottomActionSnackBar(message: Strings.Coursedates.calendarEventsAdded)
            return
        }
        
        guard let topController = UIApplication.shared.topMostController() else { return }
        
        calendar.isModalPresented = true
        
        let title = Strings.Coursedates.datesAddedAlertMessage(calendarName: calendar.calendarName)
        let alertController = UIAlertController().showAlert(withTitle: title, message: "", cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }
        
        alertController.addButton(withTitle: Strings.Coursedates.calendarViewEvents) { [weak self] _ in
            self?.trackCalendarEvent(for: .CalendarViewEvents, eventName: .CalendarViewEvents)
            if let url = URL(string: "calshow://"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
        alertController.addButton(withTitle: Strings.done) { [weak self] _ in
            self?.trackCalendarEvent(for: .CalendarAddConfirmation, eventName: .CalendarAddConfirmation)
        }
    }
    
    private func trackCalendarEvent(for displayName: AnalyticsDisplayName, eventName: AnalyticsEventName, syncReason: SyncReason? = nil, elapsedTime: Int? = nil) {
        if userEnrollment == .audit || userEnrollment == .verified {
            let pacing: Pacing = isSelfPaced ? .user : .instructor
            environment.analytics.trackCalendarEvent(displayName: displayName, eventName: eventName, userType: userEnrollment.rawValue, pacing: pacing.rawValue, courseID: courseID, syncReason: syncReason?.rawValue, elapsedTime: elapsedTime)
        }
    }
}

extension CourseDatesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dateBlocksMapSortedKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CourseDateViewCell.identifier, for: indexPath) as! CourseDateViewCell

        let index = indexPath.row
        let key = dateBlocksMapSortedKeys[index]
        let count = dateBlocksMapSortedKeys.count
        
        cell.timeline.topColor = .clear
        cell.timeline.bottomColor = .clear
                
        if index == 0 {
            cell.timeline.topColor = .clear
            cell.timeline.bottomColor = environment.styles.neutralXDark()
        } else if index == count - 1 {
            cell.timeline.topColor = environment.styles.neutralXDark()
            cell.timeline.bottomColor = .clear
        } else {
            cell.timeline.topColor = environment.styles.neutralXDark()
            cell.timeline.bottomColor = environment.styles.neutralXDark()
        }
        
        guard let blocks = dateBlocks[key] else { return cell }
        cell.index = index
        cell.delegate = self
        cell.setDueNext = !isDueNextSet
        
        if let dueNextCellIndex = dueNextCellIndex, dueNextCellIndex == index {
            cell.setDueNext = true
        }
        
        cell.blocks = blocks
        
        return cell
    }
}

extension CourseDatesViewController: UITableViewDelegate { }

extension CourseDatesViewController: PullRefreshControllerDelegate {
    func refreshControllerActivated(controller: PullRefreshController) {
        loadStreams(fromPullToRefresh: true)
    }
}

extension CourseDatesViewController: CourseDateViewCellDelegate {
    func didSelectLink(with url: URL) {
        let componentID = url.URLString
        
        if let block = courseQuerier.blockWithID(id: componentID).firstSuccess().value {
            environment.router?.navigateToComponentScreen(from: self, courseID: courseID, componentID: componentID)

            if let dateBlock = courseDateModel?.dateBlocks.first(where: { $0.firstComponentBlockID == componentID }),
               let blockURL = URL(string: dateBlock.link) {
                environment.analytics.trackCourseComponentTapped(courseID: courseID, blockID: componentID, blockType: block.typeName ?? "", link: blockURL.absoluteString)
            }

        } else if let block = courseDateModel?.dateBlocks.first(where: { $0.firstComponentBlockID == componentID }),
                  let blockURL = URL(string: block.link) {
            let message = Strings.courseContentNotAvailable
            let alertController = UIAlertController().showAlert(withTitle: title, message: message, cancelButtonTitle: Strings.cancel, onViewController: self)
            alertController.addButton(withTitle: Strings.openInBrowser) { _ in
                if UIApplication.shared.canOpenURL(blockURL) {
                    UIApplication.shared.open(blockURL, options:[:], completionHandler: nil)
                }
            }
            environment.analytics.trackCourseUnsupportedComponentTapped(courseID: courseID, blockID: componentID, link: blockURL.absoluteString)
        } else {
            Logger.logError("ANALYTICS", "Unable to load block from course dates: \(componentID)")
        }
    }
    
    func didSetDueNext(with index: Int) {
        isDueNextSet = true
        dueNextCellIndex = index
    }
}

extension CourseDatesViewController: CourseShiftDatesDelegate {
    func courseShiftDateButtonAction() {
        resetCourseDate()
    }
}

extension CourseDatesViewController: CourseDatesHeaderViewDelegate {
    func didToggleCalendarSwitch(isOn: Bool) {
        calendarState = isOn
    }
}

extension CourseDatesViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidScroll(scrollView: scrollView)
    }
}

// For use in testing only
extension CourseDatesViewController {
    func t_loadData(data: CourseDateModel) {
        populate(with: data)
        loadController.state = .Loaded
    }
}

extension CFTimeInterval {
    var millisecond: Int {
        return Int(self * 1000)
    }
}
