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

    // MARK:- Methods -
    private func setupView() {
        title = Strings.programs
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
        view.addSubview(webController.view)
        webController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    private func loadPrograms() {
        webController.loadRequest(request: NSURLRequest(url: programsURL))
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

extension ProgramsViewController: WebViewNavigationDelegate {
    
    private func enrollInCourse(with url: URL) {
        if let urlData = CourseDiscoveryHelper.parse(url: url), let courseId = urlData.courseId {
            CourseDiscoveryHelper.enrollInCourse(courseID: courseId, emailOpt: urlData.emailOptIn, from: self)
        }
    }
    
    private func navigate(to url: URL, from controller: UIViewController, bottomBar: UIView?) {
        guard let urlAction = CourseDiscoveryHelper.urlAction(from: url) else { return  }
        switch urlAction {
        case .courseDetail:
            if let courseDetailPath = CourseDiscoveryHelper.detailPathID(from: url) {
                environment.router?.showCourseDetails(from: controller, with: courseDetailPath, bottomBar: bottomBar)
            }
            break
        case .enrolledCourseDetail:
            if let urlData = CourseDiscoveryHelper.parse(url: url), let courseId = urlData.courseId {
                environment.router?.showCourseWithID(courseID: courseId, fromController: controller, animated: true)
            }
            break
        case .enrolledProgramDetail:
            if let programDetailsURL = CourseDiscoveryHelper.programDetailURL(from: url, config: environment.config) {
                environment.router?.showProgramDetails(with: programDetailsURL, from: controller)
            }
            break
        default: break
        }
    }
    
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        if let urlAction = CourseDiscoveryHelper.urlAction(from: url), urlAction == .courseEnrollment {
            enrollInCourse(with: url)
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
