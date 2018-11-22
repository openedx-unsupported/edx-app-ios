//
//  FindProgramsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 11/19/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import WebKit

class FindProgramsViewController: UIViewController {
    
    typealias Environment = OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXSessionProvider
    
    private let environment: Environment
    fileprivate var showBottomBar: Bool = true
    fileprivate let searchQuery: String?
    fileprivate let bottomBar: UIView?
    private(set) var webviewHelper: DiscoveryWebViewHelper?
    private var enrollmentConfig: EnrollmentConfig? {
        return environment.config.programEnrollment
    }
    
    // MARK:- Initializer -
    init(with environment: Environment, bottomBar: UIView?, searchQuery: String? = nil) {
        self.environment = environment
        self.bottomBar = bottomBar
        self.searchQuery = searchQuery
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(with environment: Environment, showBottomBar: Bool, bottomBar: UIView?, searchQuery: String? = nil) {
        self.init(with: environment, bottomBar: bottomBar, searchQuery: searchQuery)
        self.showBottomBar = showBottomBar
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- Methods -
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Strings.discover
        webviewHelper = DiscoveryWebViewHelper(environment: environment, delegate: self, bottomBar: showBottomBar ? bottomBar : nil, showSearch: true, searchQuery: searchQuery, discoveryType: .programs)
        if let url = enrollmentConfig?.webview.searchURL as URL? {
            webviewHelper?.searchBaseURL = url
            webviewHelper?.load(withURL: url)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if environment.session.currentUser != nil {
            webviewHelper?.refreshView()
        }
    }
}

extension FindProgramsViewController: WebViewNavigationDelegate {
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        DiscoveryHelper.navigate(to: url, from: self, bottomBar: bottomBar)
        return false
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
    
    
}
