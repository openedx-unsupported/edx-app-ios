//
//  BannerBrowserViewController.swift
//  edX
//
//  Created by Muhammad Umer on 27/09/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

protocol BannerBrowserViewControllerDelegate: AnyObject {
    func didTapOnAcknowledge()
    func didTapOnDeleteAccount()
}

class BannerBrowserViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & ReachabilityProvider & OEXStylesProvider & OEXRouterProvider
    
    private lazy var webController = AuthenticatedWebViewController(environment: environment)
        
    private let environment: Environment
    private let url: URL
    weak var delegate: BannerBrowserViewControllerDelegate?
    
    private var noticeID: String?
    
    private enum AllowedBannerURLs: String {
        case main = "https://courses.stage.edx.org/notices/render/1/"
        case tos = "https://www.edx.org/edx-terms-service"
        case policy = "https://www.edx.org/edx-privacy-policy"
        case delete = "https://account.edx.org/#delete-account"
    }
    
    init(url: URL, environment: Environment) {
        self.environment = environment
        self.url = url
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

extension BannerBrowserViewController: WebViewNavigationDelegate {
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        if let url = request.url?.URLString {
            if url == AllowedBannerURLs.main.rawValue {
                return true
            } else if url == AllowedBannerURLs.tos.rawValue {
                if self.url.URLString == AllowedBannerURLs.tos.rawValue {
                    return true
                } else {
                    environment.router?.showBannerBrowserViewController(from: self, url: URL(string: AllowedBannerURLs.tos.rawValue)!)
                }
            } else if url == AllowedBannerURLs.policy.rawValue {
                if self.url.URLString == AllowedBannerURLs.policy.rawValue {
                    return true
                } else {
                    environment.router?.showBannerBrowserViewController(from: self, url: URL(string: AllowedBannerURLs.policy.rawValue)!)
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
