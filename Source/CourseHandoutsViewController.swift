//
//  CourseHandoutsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
public class CourseHandoutsViewController: OfflineSupportViewController, UIWebViewDelegate, LoadStateViewReloadSupport {
    
    public typealias Environment = DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXAnalyticsProvider

    let courseID : String
    let environment : Environment
    let webView : UIWebView
    let loadController : LoadStateViewController
    let handouts : BackedStream<String> = BackedStream()
    
    init(environment : Environment, courseID : String) {
        self.environment = environment
        self.courseID = courseID
        self.webView = UIWebView()
        self.loadController = LoadStateViewController()
        
        super.init(env: environment)
        
        addListener()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        loadController.setupInController(controller: self, contentView: webView)
        addSubviews()
        setConstraints()
        setStyles()
        webView.delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenHandouts, courseID: courseID, value: nil)
        loadHandouts()
    }
    
    override func reloadViewData() {
        loadHandouts()
    }
    
    private func addSubviews() {
        view.addSubview(webView)
    }
    
    private func setConstraints() {
        webView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }
    
    private func setStyles() {
        self.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        self.navigationItem.title = Strings.courseHandouts
    }
    
    private func streamForCourse(course : OEXCourse) -> OEXStream<String>? {
        if let access = course.courseware_access, !access.has_access {
            return OEXStream<String>(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info))
        }
        else {
            let request = CourseInfoAPI.getHandoutsForCourseWithID(courseID: courseID, overrideURL: course.course_handouts)
            let loader = self.environment.networkManager.streamForRequest(request, persistResponse: true)
            return loader
        }
    }

    private func loadHandouts() {
        if !handouts.active {
            loadController.state = .Initial
            let courseStream = self.environment.dataManager.enrollmentManager.streamForCourseWithID(courseID: courseID)
            let handoutStream = courseStream.transform {[weak self] enrollment in
                return self?.streamForCourse(course: enrollment.course) ?? OEXStream<String>(error : NSError.oex_courseContentLoadError())
            }
            self.handouts.backWithStream(handoutStream)
        }
    }
    
    private func addListener() {
        handouts.listen(self, success: { [weak self] courseHandouts in
            if let
                displayHTML = OEXStyles.shared().styleHTMLContent(courseHandouts, stylesheet: "handouts-announcements"),
                let apiHostUrl = OEXConfig.shared().apiHostURL()
            {
                self?.webView.loadHTMLString(displayHTML, baseURL: apiHostUrl)
                self?.loadController.state = .Loaded
            }
            else {
                self?.loadController.state = LoadState.failed()
            }
            
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error: error)
        } )
    }
    
    override public func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.bottomLayoutGuide.length, right: 0)
        super.updateViewConstraints()
    }
    
    //MARK: UIWebView delegate

    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (navigationType != UIWebViewNavigationType.other) {
            if let URL = request.url {
                 UIApplication.shared.openURL(URL)
                return false
            }
        }
        return true
    }
    
    //MARK:- LoadStateViewReloadSupport method
    func loadStateViewReload() {
        loadHandouts()
    }
    
}
