//
//  CourseDatesViewController.swift
//  edX
//
//  Created by Salman on 08/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import WebKit

class CourseDatesViewController: UIViewController, InterfaceOrientationOverriding {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & ReachabilityProvider & NetworkManagerProvider & OEXRouterProvider & DataManagerProvider & OEXInterfaceProvider
    
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
        let view = CourseDatesHeaderView()
        view.accessibilityIdentifier = "CourseDatesViewController:CourseDatesHeaderView"
        view.switchIsOn = calendarState
        view.delegate = self
        return view
    }()
    
    private var courseDateModel: CourseDateModel?
    private var dateBlocksMap: [Date : [CourseDateBlock]] = [:]
    private var dateBlocksMapSortedKeys: [Date] = []
    private var isDueNextSet = false
    private var dueNextCellIndex: Int?
    
    private var courseDateBlocks: [CourseDateBlock] = []
    
    private let courseID: String
    private let environment: Environment
    
    private lazy var calendar: CalendarManager = {
        guard let course = course, let courseName = course.name else {
            return CalendarManager(courseName: "EDX")
        }
        return CalendarManager(courseName: courseName)
    }()
    
    private var course: OEXCourse? {
        return environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.course
    }
    
    private var isSelfPaced: Bool {
        guard let course = course else { return false }
        return course.isSelfPaced
    }
    
    private var userEnrollment: EnrollmentMode {
        guard let course = course, let mode = environment.interface?.enrollmentForCourse(withID: course.course_id)?.mode,
              let enrollmentType = EnrollmentMode(rawValue: mode)
        else { return .none }
    
        return enrollmentType
    }
    
    private var calendarState: Bool {
        set {
            guard let course = course, let courseName = course.name else {
                return
            }
                        
            UserDefaults.standard.setValue(newValue, forKey: courseName)
            UserDefaults.standard.synchronize()
            
            if newValue {
                trackCalendarEvent(for: .CalendarToggleOn, eventName: .CalendarToggleOn)
                
                calendar.requestAccess { [weak self] _, _, status in
                    if status == .authorized {
                        DispatchQueue.main.async {
                            self?.showAlertForCalendar()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.showCalendarSettingsAlert()
                        }
                    }
                }
            } else {
                trackCalendarEvent(for: .CalendarToggleOff, eventName: .CalendarToggleOff)
                removeEventsFromCalendar()
            }
            
        }
        get {
            guard let course = course, let courseName = course.name else {
                return false
            }
            
            return UserDefaults.standard.bool(forKey: courseName)
        }
    }
    
    init(environment: Environment, courseID: String) {
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setConstraints()
        setAccessibilityIdentifiers()
        loadStreams()
        addObserver()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.setAndLayoutTableHeaderView(header: courseDatesHeaderView)
    }
    
    private func handleCalendar() {
        switch calendar.authorizationStatus {
        case .authorized, .notDetermined:
            addEventsToCalendar()
            break
            
        case .denied, .restricted:
            showCalendarSettingsAlert()
            break
        @unknown default:
            addEventsToCalendar()
            break
        }
    }
    
    private func showCalendarSettingsAlert() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        let alertController = UIAlertController().showAlert(withTitle: Strings.settings, message: Strings.Coursedates.calendarPermissionNotDetermined, cancelButtonTitle: Strings.cancel, onViewController: self)
        alertController.addButton(withTitle: Strings.Coursedates.openSettings) { _ in
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func addEventsToCalendar() {
        calendar.requestAccess { [weak self] access, error, state in
            switch state {
            case .authorized:
                self?.trackCalendarEvent(for: .CalendarAccessAllowed, eventName: .CalendarAccessAllowed)
                break
                
            default:
                self?.trackCalendarEvent(for: .CalendarAccessDontAllow, eventName: .CalendarAccessDontAllow)
                break
            }
            
            if access {
                self?.addCourseEvents {
                    self?.showAlertForEventsAddedConfirmation()
                }
            }
        }
    }
    
    private func addCourseEvents(completion: (()->())? = nil) {
        calendar.addEventsToCalendar(for: dateBlocksMap) { [weak self] done, error in
            if done {
                self?.trackCalendarEvent(for: .CalendarAddDatesSuccess, eventName: .CalendarAddDatesSuccess)
                completion?()
            }
        }
    }
    
    private func removeEventsFromCalendar(completion: (()->())? = nil) {
        calendar.removeCalendar { [weak self] done, _ in
            if done {
                self?.trackCalendarEvent(for: .CalendarRemoveDatesSuccess, eventName: .CalendarRemoveDatesSuccess)
                completion?()
            }
        }
    }
    
    private func showAlertForCalendar() {
        let title = Strings.Coursedates.addCalendarTitle(calendarName: calendar.calendarName)
        let message = Strings.Coursedates.addCalendarPrompt(calendarName: calendar.calendarName)
        
        let alertController = UIAlertController().showAlert(withTitle: title, message: message, cancelButtonTitle: Strings.cancel, onViewController: self) { [weak self] _, _, index in
            if index == UIAlertControllerBlocksCancelButtonIndex {
                self?.trackCalendarEvent(for: .CalendarAddCancelled, eventName: .CalendarAddCancelled)
            }
        }
        
        alertController.addButton(withTitle: Strings.ok) { [weak self] _ in
            self?.trackCalendarEvent(for: .CalendarAddDates, eventName: .CalendarAddDates)
            self?.handleCalendar()
        }
    }
    
    private func showAlertForEventsAddedConfirmation() {
        let title = Strings.Coursedates.datesHasBeenAddedToYourCalendar(calendarName: calendar.calendarName)
        let alertController = UIAlertController().showAlert(withTitle: title, message: "", cancelButtonTitle: Strings.cancel, onViewController: self) { _, _, _ in }
        
        alertController.addButton(withTitle: Strings.ok) { [weak self] _ in
            self?.trackCalendarEvent(for: .CalendarAddConfirmation, eventName: .CalendarAddConfirmation)
        }
    }
    
    private func loadStreams(fromPullToRefresh: Bool = false) {
        if !fromPullToRefresh {
            loadController.state = .Initial
        }
        loadCourseDates()
        loadCourseBannerStream()
    }
    
    private func addObserver() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_SHIFT_COURSE_DATES) { _, observer, _ in
            observer.removeEventsFromCalendar()
            observer.loadStreams()
        }
    }
    
    private func setupView() {
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
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
            switch response {
            case .success((var courseDateModel, let userPreference)):
                if courseDateModel.dateBlocks.isEmpty {
                    self?.loadController.state = .failed(message: Strings.Coursedates.courseDateUnavailable)
                    self?.calendar.removeCalendar()
                } else {
                    courseDateModel.defaultTimeZone = userPreference?.timeZone
                    self?.populate(with: courseDateModel)
                    self?.loadController.state = .Loaded
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
                self?.handleDatesBanner(courseBanner: courseBanner)
                break
                
            case .failure(let error):
                Logger.logError("DatesResetBanner", "Unable to load dates reset banner: \(error.localizedDescription)")
                break
            }
        }
    }
    
    private func handleDatesBanner(courseBanner: CourseDateBannerModel) {
        if isSelfPaced {
            loadCourseDateBannerView(bannerModel: courseBanner)
        } else {
            if let status = courseBanner.bannerInfo.status, status == .upgradeToCompleteGradedBanner {
                loadCourseDateBannerView(bannerModel: courseBanner)
            } else {
                updateDatesBannerVisibility(show: false)
            }
        }
    }
    
    private func loadCourseDateBannerView(bannerModel: CourseDateBannerModel) {
        var shouldShowHeader = false
        if bannerModel.hasEnded {
            shouldShowHeader = false
            removeEventsFromCalendar()
        } else {
            shouldShowHeader = true
            trackDateBannerAppearanceEvent(bannerModel: bannerModel)
        }
        
        courseDatesHeaderView.setupView(with: bannerModel.bannerInfo, isSelfPaced: isSelfPaced)
        
        updateDatesBannerVisibility(show: shouldShowHeader)
    }
    
    private func updateDatesBannerVisibility(show: Bool) {
        courseDatesHeaderView.snp.remakeConstraints { make in
            make.leading.equalTo(tableView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(tableView).inset(StandardHorizontalMargin)
            make.top.equalTo(tableView).offset(StandardVerticalMargin)
            make.height.equalTo(show ? courseDatesHeaderView.estimatedHeight + 20 : 0)
        }
    }
    
    private func populate(with dateModel: CourseDateModel) {
        courseDateModel = dateModel
        var blocks = dateModel.dateBlocks
        
        dateBlocksMap = [:]
        
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
            if dateBlocksMap.keys.contains(key) {
                if var item = dateBlocksMap[key] {
                    item.append(block)
                    dateBlocksMap[key] = item
                }
            } else {
                dateBlocksMap[key] = [block]
            }
        }
        
        courseDateBlocks = blocks
        
        dateBlocksMapSortedKeys = dateBlocksMap.keys.sorted()
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setAccessibilityIdentifiers() {
        view.accessibilityIdentifier = "CourseDatesViewController:view"
        tableView.accessibilityIdentifier = "CourseDatesViewController:table-view"
    }
    
    private func setConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        
        updateDatesBannerVisibility(show: false)
    }
    
    private func resetCourseDate() {
        trackDatesShiftTapped()
        
        removeEventsFromCalendar()
        
        let request = CourseDateBannerAPI.courseDatesResetRequest(courseID: courseID)
        environment.networkManager.taskForRequest(request) { [weak self] result  in
            guard let weakSelf = self else { return }
            if let _ = result.error {
                weakSelf.trackDatesShiftEvent(success: false)
                weakSelf.showDateResetSnackBar(message: Strings.Coursedates.ResetDate.errorMessage)
            } else {
                weakSelf.trackDatesShiftEvent(success: true)
                weakSelf.showDateResetSnackBar(message: Strings.Coursedates.ResetDate.successMessage)
                weakSelf.postCourseDateResetNotification()
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
    
    private func trackCalendarEvent(for displayName: AnalyticsDisplayName, eventName: AnalyticsEventName) {
        if userEnrollment == .audit || userEnrollment == .verified {
            let pacing = isSelfPaced ? "self" : "instructor"
            environment.analytics.trackCalendarEvent(displayName: displayName, eventName: eventName, userType: userEnrollment.rawValue, pacing: pacing, courseID: courseID)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
            cell.timeline.bottomColor = OEXStyles.shared().neutralXDark()
        } else if index == count - 1 {
            cell.timeline.topColor = OEXStyles.shared().neutralXDark()
            cell.timeline.bottomColor = .clear
        } else {
            cell.timeline.topColor = OEXStyles.shared().neutralXDark()
            cell.timeline.bottomColor = OEXStyles.shared().neutralBlackT()
        }
        
        guard let blocks = dateBlocksMap[key] else { return cell }
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
        let courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        
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

extension CourseDatesViewController: CourseDatesShiftDelegate {
    func courseShiftDateButtonAction() {
        resetCourseDate()
    }
}

extension CourseDatesViewController: CourseDatesHeaderDelegate {
    func didToggleCalendarSwitch(isOn: Bool) {
        calendarState = isOn
    }
}

// For use in testing only
extension CourseDatesViewController {
    func t_loadData(data: CourseDateModel) {
        populate(with: data)
        loadController.state = .Loaded
    }
}
