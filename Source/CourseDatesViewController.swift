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
        self.view.backgroundColor = UIColor.white;
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
        view.addSubview(webController.view)
        navigationItem.title = Strings.courseImportantDatesTitle
        setConstraints()
        loadCourseDates()
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
        webview.filterHTML(forClass: "date-summary-container", paddingLeft: 20, paddingTop: 30, paddingRight: 0, completionHandler: {(result, error) in
            self.perform(#selector(self.showView), with:nil, afterDelay: 0.4)
        })
    }
    
    func showView() {
        webController.contentLoaded()
    }
}

extension WKWebView {
    
    func filterHTML(forClass name: String, paddingLeft: Int, paddingTop: Int, paddingRight: Int, completionHandler:((Any?, Error?) -> Swift.Void)? = nil) {
        let javascriptString = "var text=''; var divs = document.getElementsByClassName('%@'); for (i = 0; i< divs.length; i ++ ){ text  += divs[i].outerHTML;} document.getElementsByTagName('body')[0].innerHTML = text; var style = document.createElement('style'); style.innerHTML = 'body { padding-left: %dpx; padding-top: %dpx; padding-right:%dpx}'; document.head.appendChild(style);document.body.style.backgroundColor = 'white'; document.getElementsByTagName('BODY')[0].style.minHeight = 'auto'"
        evaluateJavaScript(String(format: javascriptString, name, paddingLeft, paddingTop, paddingRight), completionHandler:completionHandler)
    
    }
}
