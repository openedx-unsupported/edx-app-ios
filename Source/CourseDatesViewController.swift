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
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & ReachabilityProvider & NetworkManagerProvider & OEXRouterProvider & DataManagerProvider

    private let datesLoader = BackedStream<(CourseDateModel, UserPreference?)>()
    private let courseDateBannerLoader = BackedStream<(CourseDateBannerModel)>()
    private var stream: OEXStream<(CourseDateModel, UserPreference?)>?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableHeaderView = courseDateBannerView
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
    private lazy var courseDateBannerView = CourseDateBannerView(frame: .zero)

    private var courseDateModel: CourseDateModel?
    private var dateBlocksMap: [Date : [CourseDateBlock]] = [:]
    private var dateBlocksMapSortedKeys: [Date] = []
    private var isDueNextSet = false
    private var dueNextCellIndex: Int?
    
    private let courseID: String
    private let environment: Environment
    
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
        tableView.setAndLayoutTableHeaderView(header: courseDateBannerView)
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
        guard let isSelfPaced = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.course.isSelfPaced else {
            updateDatesBannerVisibility(with: 0)
            return
        }
        
        if isSelfPaced {
            loadCourseDateBannerView(bannerModel: courseBanner)
        } else {
            if let status = courseBanner.bannerInfo.status, status == .upgradeToCompleteGradedBanner {
                loadCourseDateBannerView(bannerModel: courseBanner)
            } else {
                updateDatesBannerVisibility(with: 0)
            }
        }
    }
    
    private func loadCourseDateBannerView(bannerModel: CourseDateBannerModel) {
        let height: CGFloat
        if bannerModel.hasEnded {
            height = 0
        } else {
            courseDateBannerView.delegate = self
            courseDateBannerView.bannerInfo = bannerModel.bannerInfo
            courseDateBannerView.setupView()
            trackDateBannerAppearanceEvent(bannerModel: bannerModel)
            height = courseDateBannerView.heightForView(width: tableView.frame.size.width)
        }
        
        updateDatesBannerVisibility(with: height)
    }
    
    private func updateDatesBannerVisibility(with height: CGFloat) {
        courseDateBannerView.snp.remakeConstraints { make in
            make.trailing.equalTo(tableView)
            make.leading.equalTo(tableView)
            make.top.equalTo(tableView)
            make.height.equalTo(height)
            make.width.equalTo(tableView.snp.width)
        }
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
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
        
        courseDateBannerView.snp.makeConstraints { make in
            make.trailing.equalTo(tableView)
            make.leading.equalTo(tableView)
            make.top.equalTo(tableView)
            make.height.equalTo(0)
            make.width.equalTo(tableView)
        }
    }
    
    private func resetCourseDate() {
        trackDatesShiftTapped()
        
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
            block.displayType
            environment.router?.navigateToComponentScreen(from: self, courseID: courseID, componentID: componentID)
        } else if let block = courseDateModel?.dateBlocks.first(where: { $0.firstComponentBlockID == componentID }),
                  let blockURL = URL(string: block.link) {
            let message = Strings.courseContentNotAvailable
            let alertController = UIAlertController().showAlert(withTitle: title, message: message, cancelButtonTitle: Strings.cancel, onViewController: self)
            alertController.addButton(withTitle: Strings.openInBrowser) { _ in
                if UIApplication.shared.canOpenURL(blockURL) {
                    UIApplication.shared.openURL(blockURL)
                }
            }
        } else {
            Logger.logError("ANALYTICS", "Unable to load block from course dates: \(componentID)")
        }
    }
    
    func didSetDueNext(with index: Int) {
        isDueNextSet = true
        dueNextCellIndex = index
    }
}

extension CourseDatesViewController: CourseDateBannerViewDelegate {
    func courseShiftDateButtonAction() {
        resetCourseDate()
    }
}

// For use in testing only
extension CourseDatesViewController {
    func t_loadData(data: CourseDateModel) {
        populate(with: data)
        loadController.state = .Loaded
    }
}
