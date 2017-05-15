//
//  CourseDatesViewController.swift
//  edX
//
//  Created by Salman on 08/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import WebKit

class CourseDatesViewController: UIViewController,UIWebViewDelegate, AuthenticatedWebViewControllerDelegate, AlwaysRequireAuthenticationOverriding {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider
    private var webview: AuthenticatedWebViewController
    private let courseID: String
    private let environment: Environment
    
    init(environment: Environment, courseID: String) {
        self.webview = AuthenticatedWebViewController(environment: environment)
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle :nil)
        self.webview.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        addChildViewController(self.webview)
        webview.didMove(toParentViewController: self)
        self.view.addSubview(self.webview.view)
        self.navigationItem.title = Strings.courseImportantDatesTitle
        self.setConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadCourseDateView()
    }
    
    func loadCourseDateView() {
        let courseDateURL = String(format: "%@/courses/%@/info", (self.environment.config.apiHostURL()?.absoluteString)!, self.courseID)
        print("\(courseDateURL)")
        let request = NSURLRequest(url: URL(string: courseDateURL)!)
        self.webview.loadRequest(request: request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setConstraints() {
        webview.view.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    // MARK: AuthenticatedWebViewController Delegate     
    func webViewDidFinishLoad(webview: WKWebView, authenticatedWebViewController :AuthenticatedWebViewController) {
        let javascript = "var text=''; var divs = document.getElementsByClassName('date-summary-container'); for (i = 0; i< divs.length; i ++ ){ text  += divs[i].outerHTML;} document.getElementsByTagName('body')[0].innerHTML = text; var style = document.createElement('style'); style.innerHTML = 'body { padding-left: 20px; padding-top: 30px;}'; document.head.appendChild(style)";
        webview.evaluateJavaScript(javascript, completionHandler: nil)
    }
}
