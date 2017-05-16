//
//  CourseDatesViewController.swift
//  edX
//
//  Created by Salman on 08/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import WebKit

class CourseDatesViewController: UIViewController, AuthenticatedWebViewControllerDelegate, AuthenticatedWebViewControllerRequireAuthentication {
    
    public typealias Environment =  OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider
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
        navigationItem.title = Strings.courseImportantDatesTitle
        self.setConstraints()
        self.loadCourseDates()
    }
    
   private func loadCourseDates() {
        let courseDateURLString = String(format: "%@/courses/%@/info", environment.config.apiHostURL()?.absoluteString ?? "", courseID)
        let request = NSURLRequest(url: URL(string: courseDateURLString)!)
        webController.loadRequest(request: request)
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setConstraints() {
        webController.view.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
    }
    
    // MARK: AuthenticatedWebViewController Delegate
    func authenticatedWebViewController(authenticatedController: AuthenticatedWebViewController, didFinishLoading webview: WKWebView) {
        webview.evaluateJavaScriptWithClass(classname: "date-summary-container", paddingLeft: 20, paddingTop: 30, paddingRight: 0)
    }
}

extension WKWebView {
    func evaluateJavaScriptWithClass(classname: String, paddingLeft: Int, paddingTop: Int, paddingRight: Int) {
        let javascriptString = "var text=''; var divs = document.getElementsByClassName('%@'); for (i = 0; i< divs.length; i ++ ){ text  += divs[i].outerHTML;} document.getElementsByTagName('body')[0].innerHTML = text; var style = document.createElement('style'); style.innerHTML = 'body { padding-left: %dpx; padding-top: %dpx; padding-right:%dpx}'; document.head.appendChild(style);"
        evaluateJavaScript(String(format: javascriptString, classname, paddingLeft, paddingTop, paddingRight), completionHandler: nil)
    }
}
