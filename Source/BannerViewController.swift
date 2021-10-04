//
//  BannerBrowserViewController.swift
//  edX
//
//  Created by Muhammad Umer on 27/09/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

protocol BannerViewControllerDelegate: AnyObject {
    func didTapOnAcknowledge()
    func didTapOnDeleteAccount()
}

class BannerViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & ReachabilityProvider & OEXStylesProvider & OEXRouterProvider
    
    private lazy var webController = AuthenticatedWebViewController(environment: environment)
        
    private let environment: Environment
    private let url: URL
    weak var delegate: BannerViewControllerDelegate?
    fileprivate var authRequired: Bool = false
    private var noticeID: String?
    
    private enum AllowedBannerURLs: String {
        case main = "https://courses.stage.edx.org/notices/render/1/"
        case tos = "https://www.edx.org/edx-terms-service"
        case policy = "https://www.edx.org/edx-privacy-policy"
        case delete = "https://account.edx.org/#delete-account"
    }
    
    init(url: URL, environment: Environment, alwaysRequireAuth: Bool = false) {
        self.environment = environment
        self.url = url
        self.authRequired = alwaysRequireAuth

        super.init(nibName: nil, bundle: nil)
        
        if url.URLString == AllowedBannerURLs.main.rawValue {
            let noticeID = url.URLString.components(separatedBy: .decimalDigits.inverted).joined()
            self.noticeID = noticeID
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
        configureSubview()
        loadRequest()
        addCloseButton()
    }

    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: 20), style: .plain, target: nil, action: nil)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "BrowserViewController:close-button"
        navigationItem.rightBarButtonItem = closeButton

        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true)
        }
    }
    
    private func loadRequest() {
        let request = NSURLRequest(url: url)
        webController.loadRequest(request: request)
        webController.webViewDelegate = self
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
        if let url = request.url?.URLString {
            if url == AllowedBannerURLs.main.rawValue {
                return true
            } else if url == AllowedBannerURLs.tos.rawValue {
                if self.url.URLString == AllowedBannerURLs.tos.rawValue {
                    return true
                } else {
                    environment.router?.showBannerViewController(from: self, url: URL(string: AllowedBannerURLs.tos.rawValue)!)
                }
            } else if url == AllowedBannerURLs.policy.rawValue {
                if self.url.URLString == AllowedBannerURLs.policy.rawValue {
                    return true
                } else {
                    environment.router?.showBannerViewController(from: self, url: URL(string: AllowedBannerURLs.policy.rawValue)!)
                }
            } else if url == AllowedBannerURLs.delete.rawValue {
                print("debug: delete this user")
            }
        }
        return false
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
}

extension BannerViewController: AuthenticatedWebViewControllerRequireAuthentication {
    func alwaysRequireAuth() -> Bool {
        return authRequired
    }
}
