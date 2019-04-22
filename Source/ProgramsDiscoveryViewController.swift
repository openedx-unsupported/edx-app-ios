//
//  ProgramsDiscoveryViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 11/19/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import WebKit

// This enum is use for Deep linking
public enum ProgramDiscoveryScreen {
    case program
    case degree
}

class ProgramsDiscoveryViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXSessionProvider
    
    private let environment: Environment
    private var showBottomBar: Bool = true
    private let searchQuery: String?
    private(set) var bottomBar: UIView?
    private(set) var pathId: String?
    private var webviewHelper: DiscoveryWebViewHelper?
    private var discoveryConfig: ProgramDiscovery? {
        return environment.config.discovery.program
    }
    private(set) var viewType: ProgramDiscoveryScreen
    
    // MARK:- Initializer -
    init(with environment: Environment, bottomBar: UIView?, searchQuery: String? = nil, type: ProgramDiscoveryScreen? = .program) {
        self.environment = environment
        self.bottomBar = bottomBar
        self.searchQuery = searchQuery
        self.viewType = type ?? .program
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(with environment: Environment, showBottomBar: Bool, bottomBar: UIView?, searchQuery: String? = nil) {
        self.init(with: environment, bottomBar: bottomBar, searchQuery: searchQuery)
        self.showBottomBar = showBottomBar
    }
    
    convenience init(with environment: Environment, pathId: String, bottomBar: UIView?, type: ProgramDiscoveryScreen? = .program) {
        self.init(with: environment, bottomBar: bottomBar, searchQuery: nil, type: type)
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
            loadProgramDetails(with: pathId)
        }
        else {
            loadPrograms(with: discoveryConfig?.webview.baseURL)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if environment.session.currentUser != nil {
            webviewHelper?.refreshView()
        }
        logScreenEvent()
    }
    
    private func logScreenEvent() {
        if let _ = pathId {
            environment.analytics.trackScreen(withName: AnalyticsScreenName.ProgramInfo.rawValue)
        }
    }
    
    func loadProgramDetails(with pathId: String) {
        self.pathId = pathId
        addBackBarButton()
        if let detailTemplate = discoveryConfig?.webview.detailTemplate?.replacingOccurrences(of: URIString.pathPlaceHolder.rawValue, with: pathId),
            let url = URL(string: detailTemplate) {
            load(url: url)
        }
        else {
            assert(false, "Unable to make detail URL.")
        }
    }
    
    private func loadPrograms(with url: URL?) {
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

extension ProgramsDiscoveryViewController: WebViewNavigationDelegate {
    
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        return !DiscoveryHelper.navigate(to: url, from: self, bottomBar: bottomBar)
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
}
