//
//  CertificateViewController.swift
//  edX
//
//  Created by Michael Katz on 11/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class CertificateViewController: UIViewController, UIWebViewDelegate, InterfaceOrientationOverriding {

    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXStylesProvider
    private let environment: Environment

    private let loadController = LoadStateViewController()
    let webView = UIWebView()
    var request: NSURLRequest?
    private let shareButton = UIButton(frame: CGRect(x: 0, y: 0, width: 26, height: 26))

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

        loadController.setupInController(controller: self, contentView: webView)
        webView.backgroundColor = OEXStyles.shared().standardBackgroundColor()

        title = Strings.Certificates.viewCertTitle
        loadController.state = .Initial

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenCertificate)
        addShareButton()
        if let request = self.request {
            webView.loadRequest(request as URLRequest)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.stopLoading()
    }

    func addShareButton() {
        let shareImage = UIImage(named: "shareCourse.png")?.withRenderingMode(.alwaysTemplate)
        shareButton.setImage(shareImage, for: .normal)
        shareButton.tintColor = environment.styles.primaryBaseColor()
        shareButton.oex_removeAllActions()
        shareButton.oex_addAction({[weak self] _ in
            self?.share()
            }, for: .touchUpInside)
        
        let shareItem = UIBarButtonItem(customView: shareButton)
        navigationItem.rightBarButtonItem = shareItem
    }

    func share() {
        guard let url = request?.url else { return }
        let text = Strings.Certificates.shareText(platformName: environment.config.platformName())
        let controller = shareTextAndALink(text: text, url: url as NSURL) { analyticsType in
            self.environment.analytics.trackCertificateShared(url: url.absoluteString, type: analyticsType)
        }
        controller.configurePresentationController(withSourceView: shareButton)
        present(controller, animated: true, completion: nil)
    }

    // MARK: - Request Loading

    func loadRequest(request : NSURLRequest) {

        let mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
        mutableRequest.httpShouldHandleCookies = false
        self.request = mutableRequest
    }


    // MARK: - Web view delegate

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        loadController.state = LoadState.failed(error: error as NSError)
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        loadController.state = .Loaded
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
    }
}
