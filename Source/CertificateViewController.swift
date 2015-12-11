//
//  CertificateViewController.swift
//  edX
//
//  Created by Michael Katz on 11/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import WebKit

class CertificateViewController: UIViewController, WKNavigationDelegate {

    typealias Environment = protocol<OEXAnalyticsProvider>
    private let environment: Environment

    private let loadController = LoadStateViewController()
    let webView = WKWebView()
    var request: NSURLRequest?


    init(environment : Environment) {
        self.environment = environment

        super.init(nibName: nil, bundle: nil)

        automaticallyAdjustsScrollViewInsets = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view = webView
        view.backgroundColor = UIColor.whiteColor()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        loadController.setupInController(self, contentView: view)
        view.alpha = 1.0
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenCertificate)
        addShareButton()
    }

    func addShareButton() {
        let shareButton = UIBarButtonItem(barButtonSystemItem: .Action, target: nil, action: nil)
        shareButton.oex_setAction { [weak self] in
            self?.share()
        }
        navigationItem.rightBarButtonItem = shareButton
    }

    func share() {
        guard let url = request?.URL else { return }
        let text = Strings.Certificates.shareText
        let controller = shareTextAndALink(text, url: url) { analyticsType in
            self.environment.analytics.trackCertificateShared(url.absoluteString, type: analyticsType)
        }
        presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - Request Loading

    func loadRequest(request : NSURLRequest) {
        loadController.state = .Initial

        let mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
        mutableRequest.HTTPShouldHandleCookies = false
        self.request = mutableRequest
        webView.loadRequest(mutableRequest)
    }


    // MARK: - Web view delegate

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        loadController.state = .Loaded
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        loadController.state = LoadState.failed(error)
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        loadController.state = LoadState.failed(error)
    }

}