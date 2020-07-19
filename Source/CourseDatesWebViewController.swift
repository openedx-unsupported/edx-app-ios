//
//  CourseDatesWebViewController.swift
//  edX
//
//  Created by Muhammad Umer on 19/07/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation


class CourseDatesWebViewController: UIViewController, InterfaceOrientationOverriding {
    
    public typealias Environment =  OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & ReachabilityProvider
    private var webController: AuthenticatedWebViewController
    private let courseID: String
    private let url: URL
    private let environment: Environment
    
    init(environment: Environment, courseID: String, url: URL) {
        webController = AuthenticatedWebViewController(environment: environment)
        self.environment = environment
        self.courseID = courseID
        self.url = url
        super.init(nibName: nil, bundle :nil)
        webController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(webController)
        webController.didMove(toParent: self)
        view.addSubview(webController.view)
        navigationItem.title = Strings.Coursedates.courseImportantDatesTitle
        setConstraints()
        loadCourseDateURL()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: AnalyticsScreenName.CourseDates.rawValue, courseID: courseID, value: url.absoluteString)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func loadCourseDateURL() {
        let request = NSURLRequest(url: url)
        webController.loadRequest(request: request)
    }
    
    private func setConstraints() {
        webController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    @objc func showLoadedCourseDates() {
        webController.setLoadControllerState(withState: LoadState.Loaded)
    }
}

extension CourseDatesWebViewController: AuthenticatedWebViewControllerDelegate {
    func authenticatedWebViewController(authenticatedController: AuthenticatedWebViewController, didFinishLoading webview: WKWebView) {
  
    }
}

extension WKWebView {
    func filterHTML(withJavaScript javaScriptString: String, classname: String, paddingLeft: Int, paddingTop: Int, paddingRight: Int, completionHandler:((Any?, Error?) -> Swift.Void)? = nil) {
        evaluateJavaScript(String(format: javaScriptString, classname, paddingLeft, paddingTop, paddingRight), completionHandler:completionHandler)
    }
}
