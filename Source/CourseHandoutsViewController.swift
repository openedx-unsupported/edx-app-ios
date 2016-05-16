//
//  CourseHandoutsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
public class CourseHandoutsViewController: UIViewController, UIWebViewDelegate {
    
    public typealias Environment = protocol<DataManagerProvider, NetworkManagerProvider, ReachabilityProvider>

    let courseID : String
    let environment : Environment
    let webView : UIWebView
    let loadController : LoadStateViewController
    let handouts : BackedStream<String> = BackedStream()
    private let insetsController = ContentInsetsController()
    
    init(environment : Environment, courseID : String) {
        self.environment = environment
        self.courseID = courseID
        self.webView = UIWebView()
        self.loadController = LoadStateViewController()
        
        super.init(nibName: nil, bundle: nil)
        
        addListener()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        loadController.setupInController(self, contentView: webView)
        addSubviews()
        setConstraints()
        setStyles()
        webView.delegate = self
        loadHandouts()
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: kReachabilityChangedNotification) { (_, observer, _) -> Void in
            if !observer.loadController.state.isLoaded && !observer.handouts.active && observer.environment.reachability.isReachable() {
                self.loadController.state = .Initial
                self.loadHandouts()
            }
        }
        
        addOfflineSupport()
    }
    
    private func addSubviews() {
        view.addSubview(webView)
    }
    
    private func setConstraints() {
        webView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }
    
    private func addOfflineSupport() {
        insetsController.setupInController(self, scrollView: webView.scrollView)
        insetsController.supportOfflineMode(environment.reachability)
    }
    
    private func setStyles() {
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        self.navigationItem.title = Strings.courseHandouts
    }
    
    private func streamForCourse(course : OEXCourse) -> Stream<String>? {
        if let access = course.courseware_access where !access.has_access {
            return Stream<String>(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info))
        }
        else {
            let request = CourseInfoAPI.getHandoutsForCourseWithID(courseID, overrideURL: course.course_handouts)
            let loader = self.environment.networkManager.streamForRequest(request, persistResponse: true)
            return loader
        }
    }

    private func loadHandouts() {
        let courseStream = self.environment.dataManager.enrollmentManager.streamForCourseWithID(courseID)
        let handoutStream = courseStream.transform {[weak self] enrollment in
            return self?.streamForCourse(enrollment.course) ?? Stream<String>(error : NSError.oex_courseContentLoadError())
        }
        
        self.handouts.backWithStream(handoutStream)
        
    }
    
    private func addListener() {
        handouts.listen(self, success: { [weak self] courseHandouts in
            if let
                displayHTML = OEXStyles.sharedStyles().styleHTMLContent(courseHandouts, stylesheet: "handouts-announcements"),
                apiHostUrl = OEXConfig.sharedConfig().apiHostURL()
            {
                self?.webView.loadHTMLString(displayHTML, baseURL: apiHostUrl)
                self?.loadController.state = .Loaded
            }
            else {
                self?.loadController.state = LoadState.failed()
            }
            
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
        } )
    }
    
    override public func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.bottomLayoutGuide.length, right: 0)
        super.updateViewConstraints()
    }
    
    //MARK: UIWebView delegate

    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (navigationType != UIWebViewNavigationType.Other) {
            if let URL = request.URL {
                 UIApplication.sharedApplication().openURL(URL)
                return false
            }
        }
        return true
    }
    
}
