//
//  BannerBrowserViewController.swift
//  edX
//
//  Created by Muhammad Umer on 27/09/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

fileprivate enum URLParameterKeys: String, RawStringExtractable {
    case screenName = "screen_name";
}

// Define banner actions here
enum BannerAction: String {
    case continueWithoutDismiss = "show_screen_without_dismissing"
    case dismiss = "dismiss"
}

enum BannerScreen: String {
    case privacyPolicy = "privacy_policy"
    case tos = "terms_of_service"
    case deleteAccount = "delete_account"
}

protocol BannerViewControllerDelegate: AnyObject {
    func navigate(with action: BannerAction, screen: BannerScreen?)
}

class BannerViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & ReachabilityProvider & OEXStylesProvider & OEXRouterProvider
    
    private lazy var webController = AuthenticatedWebViewController(environment: environment)
        
    private let environment: Environment
    private let url: URL
    weak var delegate: BannerViewControllerDelegate?
    fileprivate var authRequired: Bool = false
    private var showNavbar: Bool = false
    
    init(url: URL, title: String?, environment: Environment, alwaysRequireAuth: Bool = false, showNavbar: Bool = false) {
        self.environment = environment
        self.url = url
        self.authRequired = alwaysRequireAuth
        self.showNavbar = showNavbar

        super.init(nibName: nil, bundle: nil)
        webController.webViewDelegate = self
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        view.backgroundColor = environment.styles.standardBackgroundColor()
        
        configureSubview()
        loadRequest()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = !showNavbar
    }
    
    private func loadRequest() {
        let request = NSURLRequest(url: url)
        webController.loadRequest(request: request)
    }
    
    private func configureSubview() {
        addSubviews()
    }
    
    private func addSubviews() {
        addChild(webController)
        webController.didMove(toParent: self)
        view.addSubview(webController.view)
        
        webController.view.snp.remakeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

extension BannerViewController: WebViewNavigationDelegate {
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let URL = request.url else { return true }

        return !navigate(url: URL)
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }

    private func navigate(url: URL) -> Bool {
        guard let action = urlAction(from: url) else { return false }
        let screen = bannerScreen(from: url)

        delegate?.navigate(with: action, screen: screen)

        return true
    }

    private func urlAction(from url: URL) -> BannerAction? {
        guard url.isValidAppURLScheme, let url = BannerAction(rawValue: url.appURLHost) else {
            return nil
        }
        return url
    }

    private  func bannerScreen(from url: URL) -> BannerScreen? {
        guard url.isValidAppURLScheme,
              let screenName = url.queryParameters?[URLParameterKeys.screenName] as? String,
              let bannerScreen = BannerScreen(rawValue: screenName)
        else {
            return nil
        }

        return bannerScreen
    }
}

extension BannerViewController: AuthenticatedWebViewControllerRequireAuthentication {
    func alwaysRequireAuth() -> Bool {
        return authRequired
    }
}
