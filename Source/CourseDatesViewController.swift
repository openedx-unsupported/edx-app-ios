//
//  CourseDatesViewController.swift
//  edX
//
//  Created by Salman on 08/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import WebKit

class CourseDatesViewController: UIViewController, AuthenticatedWebViewControllerDelegate, InterfaceOrientationOverriding {
    
    public typealias Environment =  OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider
    private var webController: AuthenticatedWebViewController
    private let courseID: String
    private let environment: Environment
    
    init(environment: Environment, courseID: String) {
        webController = AuthenticatedWebViewController(environment: environment)
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle :nil)
        webController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
        view.addSubview(webController.view)
        navigationItem.title = Strings.Coursedates.courseImportantDatesTitle
        setConstraints()
        loadCourseDates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
           environment.analytics.trackScreen(withName: AnalyticsScreenName.CourseDates.rawValue, courseID: courseID, value: nil)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func loadCourseDates() {
        let courseDateURLString = String(format: "%@/courses/%@/course/mobile_dates_fragment", environment.config.apiHostURL()?.absoluteString ?? "", courseID)
        let request = NSURLRequest(url: URL(string: courseDateURLString)!)
        webController.loadRequest(request: request)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setConstraints() {
        webController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    // MARK: AuthenticatedWebViewController Delegate
    func authenticatedWebViewController(authenticatedController: AuthenticatedWebViewController, didFinishLoading webview: WKWebView) {
        
        let path = Bundle.main.path(forResource: "course-dates", ofType: "js") ?? ""
        let javaScriptString = try? String(contentsOfFile: path, encoding: String.Encoding.utf8)
        webview.filterHTML(withJavaScript: javaScriptString!, classname: "date-summary-container", paddingLeft: 20, paddingTop: 30, paddingRight: 0, completionHandler: {[weak self] (result, error) in
            let isCourseDateAvailable = result as? Bool
            if isCourseDateAvailable == true
            {
                self?.perform(#selector(self?.showLoadedCourseDates), with:nil, afterDelay: 0.4)
            }
            else{
                authenticatedController.showError(error: nil, icon: nil, message:Strings.Coursedates.courseDateUnavailable)
            }
        })
    }
    
    func showLoadedCourseDates() {
        webController.setLoadControllerState(withState: LoadState.Loaded)
    }
}

extension WKWebView {
    
    func filterHTML(withJavaScript javaScriptString: String, classname: String, paddingLeft: Int, paddingTop: Int, paddingRight: Int, completionHandler:((Any?, Error?) -> Swift.Void)? = nil) {
        evaluateJavaScript(String(format: javaScriptString, classname, paddingLeft, paddingTop, paddingRight), completionHandler:completionHandler)
    }
}
