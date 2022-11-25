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
        let view = CourseDashboardHeaderView(course: course, environment: environment)
        view.accessibilityIdentifier = "NewCourseDashboardViewController:header-view"
        view.delegate = self
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.accessibilityIdentifier = "NewCourseDashboardViewController:table-view"
        tableView.register(NewDashboardErrorPlaceHolderCell.self, forCellReuseIdentifier: NewDashboardErrorPlaceHolderCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private var course: OEXCourse?
    private var error: NSError?
    
    private let courseStream: BackedStream<UserCourseEnrollment>
    private let loadStateController: LoadStateViewController
    
    private let environment: Environment
    private let courseID: String
    
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
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
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
    
    private func resultLoaded(result : Result<UserCourseEnrollment>) {
        switch result {
        case .success(let enrollment):
            course = enrollment.course
            loadedCourse(withCourse: enrollment.course)
        case .failure(let error):
            if !courseStream.active {
                loadStateController.state = .Loaded
                self.error = error
                tableView.reloadData()
            }
        }
    }
    
    private func verifyAccess(forCourse course: OEXCourse){
        if let access = course.courseware_access, !access.has_access {
            loadStateController.state = .Loaded
            self.error = OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info)
            tableView.reloadData()
        } else {
            self.course = course
            loadStateController.state = .Loaded
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

extension NewCourseDashboardViewController: UITableViewDelegate {
    
}

extension NewCourseDashboardViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if error != nil {
            return 1
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let error = error {
            let cell = tableView.dequeueReusableCell(withIdentifier: NewDashboardErrorPlaceHolderCell.identifier, for: indexPath) as! NewDashboardErrorPlaceHolderCell
            cell.setError(error)
            return cell
        } else {
            return UITableViewCell()
        }
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
}
