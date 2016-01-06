//
//  CourseCatalogDetailViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/3/15.
//  Copyright © 2015 edX. All rights reserved.
//

import WebKit
import UIKit

class CourseCatalogDetailViewController: UIViewController {
    private let courseID: String
    
    typealias Environment = protocol<OEXAnalyticsProvider, DataManagerProvider, NetworkManagerProvider, OEXRouterProvider>
    
    private let environment: Environment
    private lazy var loadController = LoadStateViewController()
    private let aboutContainer = UIScrollView()
    private lazy var aboutView : CourseCatalogDetailView = {
        return CourseCatalogDetailView(frame: CGRectZero, environment: self.environment)
    }()
    private let courseStream = BackedStream<OEXCourse>()
    
    init(environment : Environment, courseID : String) {
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(aboutContainer)
        aboutContainer.snp_makeConstraints {make in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        aboutContainer.addSubview(aboutView)
        aboutView.snp_makeConstraints { make in
            make.top.equalTo(aboutContainer)
            make.leading.equalTo(aboutContainer)
            make.trailing.equalTo(aboutContainer)
            make.width.equalTo(aboutContainer)
        }
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        self.loadController.setupInController(self, contentView: aboutContainer)
        listen()
        load()
    }
    
    private func listen() {
        self.courseStream.listen(self,
            success: {[weak self] course in
                self?.aboutView.applyCourse(course)
                self?.aboutView.enrollAction = {[weak self] completion in
                    self?.enrollInCourse(completion)
                }
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            }
        )
        self.aboutView.loaded.listen(self) {[weak self] _ in
            self?.loadController.state = .Loaded
        }
    }
    
    private func load() {
        let request = CourseCatalogAPI.getCourse(courseID)
        let stream = environment.networkManager.streamForRequest(request)
        self.courseStream.backWithStream(stream)
    }
    
    private func showCourseScreenWithMessage(message: String) {
        self.environment.router?.showMyCourses(animated: true, pushingCourseWithID:courseID)
        
        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(EnrollmentShared.overlayMessageDelay * NSTimeInterval(NSEC_PER_SEC)))
        dispatch_after(after, dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotificationName(EnrollmentShared.successNotification, object: message, userInfo: nil)
        }
    }
    
    private func enrollInCourse(completion : () -> Void) {
        
        let notEnrolled = environment.dataManager.enrollmentManager.enrolledCourseWithID(self.courseID) == nil
        
        guard notEnrolled else {
            self.showCourseScreenWithMessage(Strings.findCoursesAlreadyEnrolledMessage)
            completion()
            return
        }
        
        let courseID = self.courseID
        let request = CourseCatalogAPI.enroll(courseID)
        environment.networkManager.taskForRequest(request) {[weak self] response in
            if response.response?.httpStatusCode.is2xx ?? false {
                self?.environment.analytics.trackUserEnrolledInCourse(courseID)
                self?.showCourseScreenWithMessage(Strings.findCoursesEnrollmentSuccessfulMessage)
            }
            else {
                self?.showOverlayMessage(Strings.findCoursesEnrollmentErrorDescription)
            }
            completion()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // add bottom padding
        aboutContainer.contentSize = CGSizeMake(aboutView.bounds.size.width, aboutView.bounds.size.height + StandardVerticalMargin)
    }
}
// Testing only
extension CourseCatalogDetailViewController {
    
    var t_loaded : Stream<()> {
        return self.aboutView.loaded
    }
    
    func t_enrollInCourse(completion : () -> Void) {
        enrollInCourse(completion)
    }
    
}
