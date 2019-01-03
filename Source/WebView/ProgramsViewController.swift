//
//  ProgramsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 7/13/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import WebKit

class ProgramsViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXRouterProvider & ReachabilityProvider
    fileprivate let environment: Environment
    private let webController: AuthenticatedWebViewController
    private let programsURL: URL
    
    init(environment: Environment, programsURL: URL) {
        webController = AuthenticatedWebViewController(environment: environment)
        self.environment = environment
        self.programsURL = programsURL
        super.init(nibName: nil, bundle: nil)
        webController.webViewDelegate = self

        setupView()
        loadPrograms()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK:- Methods -
    private func setupView() {
        title = Strings.programs
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
        view.addSubview(webController.view)
        webController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    private func loadPrograms() {
        webController.loadRequest(request: NSURLRequest(url: programsURL))
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

extension ProgramsViewController: WebViewNavigationDelegate {
    
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        return !DiscoveryHelper.navigate(to: url, from: self, bottomBar: nil)
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
}
