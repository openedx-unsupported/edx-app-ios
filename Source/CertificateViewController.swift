//
//  CertificateViewController.swift
//  edX
//
//  Created by Michael Katz on 11/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class CertificateViewController: UIViewController, UIWebViewDelegate, InterfaceOrientationOverriding {

    typealias Environment = protocol<OEXAnalyticsProvider, OEXConfigProvider>
    private let environment: Environment

    private let loadController = LoadStateViewController()
    let webView = UIWebView()
    var request: NSURLRequest?


    init(environment : Environment) {
        self.environment = environment

        super.init(nibName: nil, bundle: nil)

        automaticallyAdjustsScrollViewInsets = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        webView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }

        webView.delegate = self

        loadController.setupInController(self, contentView: webView)
        webView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()

        title = Strings.Certificates.viewCertTitle
        loadController.state = .Initial

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenCertificate)
        addShareButton()
        if let request = self.request {
            webView.loadRequest(request)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        webView.stopLoading()
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
        let text = Strings.Certificates.shareText(platformName: environment.config.platformName())
        let controller = shareTextAndALink(text, url: url) { analyticsType in
            self.environment.analytics.trackCertificateShared(url.absoluteString!, type: analyticsType)
        }
        presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - Request Loading

    func loadRequest(request : NSURLRequest) {

        let mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
        mutableRequest.HTTPShouldHandleCookies = false
        self.request = mutableRequest
    }


    // MARK: - Web view delegate

    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        loadController.state = LoadState.failed(error)
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        loadController.state = .Loaded
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
    }
}
