//
//  FindProgramDetailViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 11/20/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation
import WebKit

class FindProgramDetailViewController: UIViewController {
    
    typealias Environment = OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXSessionProvider
    
    private let environment: Environment
    private let pathId: String
    fileprivate let bottomBar: UIView?
    private(set) var webviewHelper: DiscoveryWebViewHelper?
    private var enrollmentConfig: EnrollmentConfig? {
        return environment.config.programEnrollment
    }
    
    // MARK:- Initializer -
    init(with environment: Environment, pathId: String, bottomBar: UIView?) {
        self.environment = environment
        self.pathId = pathId
        self.bottomBar = bottomBar
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- Methods -
    override func viewDidLoad() {
        super.viewDidLoad()
        webviewHelper = DiscoveryWebViewHelper(environment: environment, delegate: self, bottomBar: bottomBar, showSearch: false, searchQuery: nil, discoveryType: .programs)
        if let detailTemplate = enrollmentConfig?.webview.detailTemplate?.replacingOccurrences(of: URIString.pathPlaceHolder.rawValue, with: pathId),
            let url = URL(string: detailTemplate) {
            webviewHelper?.load(withURL: url)
        }
        
        navigationItem.title = Strings.discover
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if environment.session.currentUser != nil {
            webviewHelper?.refreshView()
        }
        addBackButton()
    }
}

extension FindProgramDetailViewController: WebViewNavigationDelegate {
    
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        DiscoveryHelper.navigate(to: url, from: self, bottomBar: bottomBar)
        return false
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
    
}
