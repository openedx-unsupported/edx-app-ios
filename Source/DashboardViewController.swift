//
//  DashboardViewController.swift
//  edX
//
//  Created by MuhammadUmer on 18/11/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider & RemoteConfigProvider & ServerConfigProvider
    
    private var course: OEXCourse?
    
    private let courseStream: BackedStream<UserCourseEnrollment>
    private let loadStateController: LoadStateViewController
    
    private let environment: Environment
    private let courseID: String
    
    private lazy var headerView: DashboardHeaderView = {
        let headerView = DashboardHeaderView(course: course, environment: environment)
        headerView.delegate = self
        return headerView
    }()
    
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
        
        view.backgroundColor = environment.styles.neutralWhiteT()
        
        loadStateController.setupInController(controller: self, contentView: view)
        
        loadCourseStream()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.setHidesBackButton(true, animated: true)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenCourseDashboard, courseID: courseID, value: nil)
    }
    
    private func addSubViews() {
        view.addSubview(headerView)
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            make.height.equalTo(StandardVerticalMargin * 20)
        }
    }
    
    private func loadCourseStream() {
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID: courseID))
        courseStream.listen(self) { [weak self] in
            self?.resultLoaded(result: $0)
        }
    }
    
    private func loadedCourse(withCourse course: OEXCourse) {
        verifyAccess(forCourse: course)
        addSubViews()
    }
    
    private func resultLoaded(result : Result<UserCourseEnrollment>) {
        switch result {
        case .success(let enrollment):
            course = enrollment.course
            loadedCourse(withCourse: enrollment.course)
        case .failure(let error):
            if !courseStream.active {
                // enrollment list is cached locally, so if the stream is still active we may yet load the course
                // don't show failure until the stream is done
                loadStateController.state = .failed(error: error)
            }
        }
    }
    
    private func verifyAccess(forCourse course: OEXCourse){
        if let access = course.courseware_access, !access.has_access {
            loadStateController.state = .failed(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info), icon: Icon.UnknownError)
        } else {
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

extension DashboardViewController: DashboardHeaderViewDelegate {
    func didTapOnValueProp() {
        guard let course = course else { return }
        environment.router?.showValuePropDetailView(from: self, screen: .courseDashboard, course: course) { [weak self] in
            self?.environment.analytics.trackValuePropModal(with: .CourseDashboard, courseId: course.course_id ?? "")
        }
        environment.analytics.trackValuePropLearnMore(courseID: course.course_id ?? "", screenName: .CourseDashboard)
    }
    
    func didTapOnClose() {
        navigationController?.popViewController(animated: true)
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
