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
        self.webController = AuthenticatedWebViewController(environment: environment)
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle :nil)
        self.webController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
        self.view.addSubview(webController.view)
        self.navigationItem.title = Strings.courseImportantDatesTitle
        self.setConstraints()
        self.loadCourseDates()
    }
    
   private func loadCourseDates() {
        let courseDateURLString = String(format: "%@/courses/%@/info", (self.environment.config.apiHostURL()?.absoluteString)!, self.courseID)
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
        let javascript = "var text=''; var divs = document.getElementsByClassName('date-summary-container'); for (i = 0; i< divs.length; i ++ ){ text  += divs[i].outerHTML;} document.getElementsByTagName('body')[0].innerHTML = text; var style = document.createElement('style'); style.innerHTML = 'body { padding-left: 20px; padding-top: 30px;}'; document.head.appendChild(style)";
        webview.evaluateJavaScript(javascript, completionHandler: nil)
    }
}
