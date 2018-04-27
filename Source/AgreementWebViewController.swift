//
//  AgreementWebViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 4/27/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class AgreementWebViewController: UIViewController, UIWebViewDelegate {
    
    // MARK: UI Properties
    lazy var webView: UIWebView = {
        let webView = UIWebView()
        webView.accessibilityIdentifier = "AgreementWebViewController:web-view"
        webView.delegate = self
        return webView
    }()
    
    lazy var separatorView: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "AgreementWebViewController:separator-view"
        view.backgroundColor = OEXStyles.shared().neutralLight()
        return view
    }()
    
    lazy var closeButton: UIButton = {
        let style = OEXMutableTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().neutralBlack())
        let button = UIButton()
        button.accessibilityIdentifier = "AgreementWebViewController:close-button"
        button.setAttributedTitle(style.attributedString(withText: Strings.close), for: .normal)
        button.oex_addAction({ [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }, for: .touchUpInside)
        return button
    }()
    
    lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.accessibilityIdentifier = "AgreementWebViewController:indicator-view"
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()
    
    // MARK: Properties
    private let url: URL
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Initializer
    init(with url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UIViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubViews()
        webView.loadRequest(URLRequest(url: url))
    }
    
    private func addSubViews() {
        view.addSubview(webView)
        view.addSubview(closeButton)
        view.addSubview(indicatorView)
        view.addSubview(separatorView)
        configureConstraints()
    }
    
    private func configureConstraints() {
        closeButton.snp_makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.bottom.equalTo(view)
            make.height.equalTo(44)
        }
        
        separatorView.snp_makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.bottom.equalTo(closeButton.snp_top)
            make.height.equalTo(1)
        }
        
        webView.snp_makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.top.equalTo(view)
            make.bottom.equalTo(separatorView.snp_top)
        }
        
        indicatorView.snp_makeConstraints { make in
            make.center.equalTo(webView)
        }
    }
    
    // MARK: UIWebViewDelegate Methods
    func webViewDidStartLoad(_ webView: UIWebView) {
        indicatorView.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        indicatorView.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        indicatorView.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url, !url.isFileURL else {
            return true
        }
        if navigationType == .linkClicked {
            UIApplication.shared.openURL(url)
            return false
        }
        return true
    }
}
