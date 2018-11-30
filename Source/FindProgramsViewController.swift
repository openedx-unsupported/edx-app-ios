//
//  FindProgramsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 11/19/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import WebKit

class FindProgramsViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXSessionProvider
    
    private let environment: Environment
    fileprivate var showBottomBar: Bool = true
    fileprivate let searchQuery: String?
    fileprivate let bottomBar: UIView?
    private(set) var pathId: String?
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
    
    convenience init(with environment: Environment, pathId: String, bottomBar: UIView?) {
        self.init(with: environment, bottomBar: bottomBar, searchQuery: nil)
        self.pathId = pathId
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- Methods -
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Strings.discover
        if let pathId = pathId {
            addBackBarButton()
            if let detailTemplate = enrollmentConfig?.webview.detailTemplate?.replacingOccurrences(of: URIString.pathPlaceHolder.rawValue, with: pathId),
                let url = URL(string: detailTemplate) {
                load(url: url)
            }
        }
        else {
            if let url = enrollmentConfig?.webview.searchURL as URL? {
                webviewHelper?.searchBaseURL = url
                load(url: url, searchQuery: searchQuery, showBottomBar: showBottomBar, showSearch: true)
            }
        }
        
    }
    
    private func load(url :URL, searchQuery: String? = nil, showBottomBar: Bool = true, showSearch: Bool = false) {
        webviewHelper = DiscoveryWebViewHelper(environment: environment, delegate: self, bottomBar: showBottomBar ? bottomBar : nil, showSearch: showSearch, searchQuery: searchQuery, discoveryType: .programs)
        webviewHelper?.load(withURL: url)
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
