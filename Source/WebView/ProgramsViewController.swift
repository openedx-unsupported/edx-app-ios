//
//  ProgramsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 7/13/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import WebKit

public enum ProgramScreen {
    case base
    case detail
}

class ProgramsViewController: UIViewController, InterfaceOrientationOverriding, PullRefreshControllerDelegate, ScrollableDelegateProvider {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXRouterProvider & ReachabilityProvider & OEXStylesProvider & NetworkManagerProvider
    
    private let environment: Environment
    private(set) var programsURL: URL
    private(set) var type: ProgramScreen
    
    private let webController: AuthenticatedWebViewController
    private let refreshController = PullRefreshController()
    
    weak var scrollableDelegate: ScrollableDelegate?
    private var scrollByDragging = false
    
    init(environment: Environment, programsURL: URL, viewType type: ProgramScreen? = .base) {
        webController = AuthenticatedWebViewController(environment: environment)
        self.environment = environment
        self.programsURL = programsURL
        self.type = type ?? .base
        super.init(nibName: nil, bundle: nil)
        webController.webViewDelegate = self
        webController.delegate = self
        webController.scrollView.delegate = self
        setupView()
        loadPrograms()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = environment.styles.standardBackgroundColor()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: AnalyticsDisplayName.MyPrograms.rawValue)
    }
    
    // MARK:- Methods -
    private func setupView() {
        title = Strings.programs
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        addChild(webController)
        webController.didMove(toParent: self)
        view.addSubview(webController.view)
        webController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        refreshController.setupInScrollView(scrollView: webController.scrollView)
        refreshController.delegate = self
    }
    
    private func loadPrograms() {
        webController.loadRequest(request: NSURLRequest(url: programsURL))
    }
    
    func loadPrograms(with url: URL) {
        programsURL = url
        webController.loadRequest(request: NSURLRequest(url: url))
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    //MARK: PullRefreshControllerDelegate
    public func refreshControllerActivated(controller: PullRefreshController) {
        loadPrograms()
    }
}

extension ProgramsViewController: AuthenticatedWebViewControllerDelegate {
    func authenticatedWebViewController(authenticatedController: AuthenticatedWebViewController, didFinishLoading webview: WKWebView) {
        refreshController.endRefreshing()
        webController.setLoadControllerState(withState: .Loaded)
    }
}

extension ProgramsViewController: WebViewNavigationDelegate {
    
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        return !DiscoveryHelper.navigate(to: url, from: self, bottomBar: nil, environment: environment)
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
}

extension ProgramsViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollByDragging = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollByDragging {
            scrollableDelegate?.scrollViewDidScroll(scrollView: scrollView)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollByDragging = false
    }
}
