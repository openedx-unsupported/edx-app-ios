//
//  DegreesViewController.swift
//  edX
//
//  Created by Salman on 29/01/2019.
//  Copyright © 2019 edX. All rights reserved.
//

import UIKit
import WebKit

class DegreesViewController: UIViewController {

    typealias Environment = OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXSessionProvider
    
    private let environment: Environment
    private var showBottomBar: Bool = true
    private let searchQuery: String?
    private(set) var bottomBar: UIView?
    private(set) var pathId: String?
    private var webviewHelper: DiscoveryWebViewHelper?
    private var discoveryConfig: DegreeDiscovery? {
        return environment.config.discovery.degree
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
    
    override func viewDidLoad() {
        navigationItem.title = Strings.degrees
        super.viewDidLoad()
        loadDegrees(with: discoveryConfig?.webview.baseURL)
    }
    
    private func loadDegrees(with url: URL?) {
        if let url = url {
            load(url: url, searchQuery: searchQuery, showBottomBar: showBottomBar, showSearch: true, searchBaseURL: url)
        }
        else {
            assert(false, "Unable to get search URL.")
        }
    }
    
    private func load(url :URL, searchQuery: String? = nil, showBottomBar: Bool = true, showSearch: Bool = false, searchBaseURL: URL? = nil) {
        webviewHelper = DiscoveryWebViewHelper(environment: environment, delegate: self, bottomBar: showBottomBar ? bottomBar : nil, showSearch: showSearch, searchQuery: searchQuery, discoveryType: .program)
        webviewHelper?.baseURL = searchBaseURL
        webviewHelper?.load(withURL: url)
    }
}

extension DegreesViewController: WebViewNavigationDelegate {
    
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        return !DiscoveryHelper.navigate(to: url, from: self, bottomBar: bottomBar)
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
}
