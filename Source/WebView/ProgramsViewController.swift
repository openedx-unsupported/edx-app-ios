//
//  ProgramsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 7/13/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import WebKit

class ProgramsViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXRouterProvider & ReachabilityProvider
    fileprivate let environment: Environment
    private let webController: AuthenticatedWebViewController
    private let programsURL: URL
    fileprivate var request: NSURLRequest? = nil
    
    init(environment: Environment, programsURL: URL) {
        webController = AuthenticatedWebViewController(environment: environment)
        self.environment = environment
        self.programsURL = programsURL
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK:- Methods -
    func setupView() {
        title = Strings.programs
        navigationController?.navigationItem.backBarButtonItem?.title = nil
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
        view.addSubview(webController.view)
        webController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    func loadPrograms() {
        request = NSURLRequest(url: programsURL)
        if let request = request {
            webController.loadRequest(request: request)
        }
    }
    
    fileprivate func enrollPorgramCourse(url: URL) {
        if let urlData = CourseDiscoveryHelper.parse(url: url), let courseId = urlData.courseId {
            CourseDiscoveryHelper.enrollInCourse(courseID: courseId, emailOpt: urlData.emailOptIn, from: self)
        }
    }
    
    fileprivate func navigate(to url: URL, from controller: UIViewController, bottomBar: UIView?) {
        guard let appURLHost = CourseDiscoveryHelper.appURL(url: url) else { return  }
        switch appURLHost {
        case .courseDetail:
            if let courseDetailPath = CourseDiscoveryHelper.getDetailPath(from: url) {
                environment.router?.showCourseDetails(from: controller, with: courseDetailPath, bottomBar: bottomBar)
            }
            break
        case .enrolledCourseDetail:
            if let urlData = CourseDiscoveryHelper.parse(url: url), let courseId = urlData.courseId {
                environment.router?.showCourseWithID(courseID: courseId, fromController: controller, animated: true)
            }
            break
        case .enrolledProgramDetail:
            if let programDetailsURL = CourseDiscoveryHelper.programDetailURL(from: url) {
                environment.router?.showProgramDetails(with: programDetailsURL, from: controller)
            }
            break
        default: break
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

extension ProgramsViewController: WebViewDelegate {
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        if let appURLHost = CourseDiscoveryHelper.appURL(url: url), appURLHost == .courseEnrollment {
            enrollPorgramCourse(url: url)
        }
        else {
            navigate(to: url, from: self, bottomBar: nil)
        }
        return false
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
}
