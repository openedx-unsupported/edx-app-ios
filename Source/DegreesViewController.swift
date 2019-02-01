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

    typealias Environment = OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider & OEXAnalyticsProvider
    
    private let environment: Environment
    private var showBottomBar: Bool = true
    fileprivate var bottomBar: UIView?
    private var webviewHelper: DiscoveryWebViewHelper?
    private var degreeConfig: DegreeDiscovery? {
        return environment.config.discovery.degree
    }
    
    // MARK:- Initializer -
    init(with environment: Environment, showBottomBar: Bool, bottomBar: UIView?) {
        self.environment = environment
        self.bottomBar = bottomBar
        self.showBottomBar = showBottomBar
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Strings.degrees
        loadDegrees()
    }
    
    private func loadDegrees() {
        guard let url = degreeConfig?.webview.baseURL else {
            assert(false, "Unable to get base URL.")
            return
        }
        webviewHelper = DiscoveryWebViewHelper(environment: environment, delegate: self, bottomBar: showBottomBar ? bottomBar : nil, showSearch: degreeConfig?.webview.searchEnabled ?? false, searchQuery: nil, discoveryType: .degree)
        webviewHelper?.baseURL = url
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
