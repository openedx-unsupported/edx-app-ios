//
//  ProgramsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 7/13/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import WebKit

let myProgramsBaseURL = "https://courses.edx.org/dashboard"
let myProgramsPath = "/programs_fragment/?mobile_only=true"

class ProgramsViewController: UIViewController {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXRouterProvider
    fileprivate let environment: Environment?
    private let webController: AuthenticatedWebViewController
    private let programDetailsURL: URL?
    
    init(environment: Environment, programDetailsURL: URL? = nil) {
        webController = AuthenticatedWebViewController(environment: environment)
        self.environment = environment
        self.programDetailsURL = programDetailsURL
        super.init(nibName: nil, bundle: nil)
        webController.webViewDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadPrograms()
    }

    // MARK:- Methods -
    func setupView() {
        title = Strings.programs
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
        view.addSubview(webController.view)
        webController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    func loadPrograms() {
        let urlToLoad: URL
        if let programDetailsURL = programDetailsURL {
            urlToLoad = programDetailsURL
        }
        else {
            guard let myProgramsURL  = URL(string: "\(myProgramsBaseURL)\(myProgramsPath)") else { return }
            urlToLoad = myProgramsURL
        }
        let request = NSURLRequest(url: urlToLoad)
        webController.loadRequest(request: request)
    }
    
    fileprivate func enrollPorgramCourse(url: URL) {
        if let urlData = CourseHelper.parse(url: url), let courseId = urlData.courseId {
            CourseHelper.enrollInCourse(courseID: courseId, emailOpt: urlData.emailOptIn, from: self)
        }
    }
    
    @objc
    fileprivate func navigate(to url: URL, from controller: UIViewController, bottomBar: UIView?) -> Bool {
        guard let appURLHost = CourseHelper.appURLHostIfValid(url: url) else { return false }
        switch appURLHost {
        case .courseDetail:
            if let courseDetailPath = CourseHelper.getCourseDetailPath(from: url) {
                environment?.router?.showCourseDetails(from: controller, with: courseDetailPath, bottomBar: bottomBar)
            }
            break
        case .enrolledCourseDetail:
            if let urlData = CourseHelper.parse(url: url), let courseId = urlData.courseId {
                environment?.router?.showCourseWithID(courseID: courseId, fromController: controller, animated: true)
            }
            break
        case .enrolledProgramDetail:
            if let programDetailsURL = CourseHelper.getEnrolledProgramDetailsURL(from: url) {
                environment?.router?.showEnrolledProgramDetails(with: programDetailsURL, from: controller)
            }
            break
        default: break
        }
        return true
    }
}

extension ProgramsViewController: WebViewDelegate {
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        if let appURLHost = CourseHelper.appURLHostIfValid(url: url), appURLHost == .courseEnrollment {
            enrollPorgramCourse(url: url)
        }
        else {
            let didNavigate = navigate(to: url, from: self, bottomBar: nil)
            return !didNavigate
        }
        return true
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
}
