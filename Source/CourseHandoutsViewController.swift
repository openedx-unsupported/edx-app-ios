//
//  CourseHandoutsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
public class CourseHandoutsViewController: UIViewController, UIWebViewDelegate {
    
    public class Environment : NSObject {
        let dataManager : DataManager
        let networkManager : NetworkManager
        let styles : OEXStyles
        
        init(dataManager : DataManager, networkManager : NetworkManager, styles : OEXStyles) {
            self.dataManager = dataManager
            self.networkManager = networkManager
            self.styles = styles
        }
    }

    let courseID : String
    let environment : Environment
    let webView : UIWebView
    let loadController : LoadStateViewController
    let handouts : BackedStream<String> = BackedStream()
    
    init(environment : Environment, courseID : String) {
        self.environment = environment
        self.courseID = courseID
        self.webView = UIWebView()
        self.loadController = LoadStateViewController(styles: self.environment.styles)
        
        super.init(nibName: nil, bundle: nil)
    }

    required public init(coder aDecoder: NSCoder) {
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
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        self.navigationItem.title = OEXLocalizedString("COURSE_HANDOUTS", nil)
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
        if let courseStream = self.environment.dataManager.interface?.courseStreamWithID(courseID) {
            let handoutStream = courseStream.transform {[weak self] course in
                return self?.streamForCourse(course) ?? Stream<String>(error : NSError.oex_courseContentLoadError())
            }
        
            self.handouts.backWithStream(handoutStream)
        }

        addListener()
        
    }
    
    private func addListener() {
        handouts.listenOnce(self, fireIfAlreadyLoaded: true, success: { [weak self]courseHandouts in
            let displayHTML = self?.environment.styles.styleHTMLContent(courseHandouts)
            if let apiHostUrl = OEXConfig.sharedConfig().apiHostURL() {
                self?.webView.loadHTMLString(displayHTML, baseURL: NSURL(string: apiHostUrl))
            }
            
            self?.loadController.state = .Loaded
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error: error)
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
