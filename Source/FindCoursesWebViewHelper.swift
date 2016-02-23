//
//  FindCoursesWebViewHelper.swift
//  edX
//
//  Created by Akiva Leffert on 11/9/15.
//  Copyright © 2015-2016 edX. All rights reserved.
//

import UIKit
import WebKit

@objc protocol FindCoursesWebViewHelperDelegate : class {
    func webViewHelper(helper : FindCoursesWebViewHelper, shouldLoadLinkWithRequest request: NSURLRequest) -> Bool
    func containingControllerForWebViewHelper(helper : FindCoursesWebViewHelper) -> UIViewController
}

class FindCoursesWebViewHelper: NSObject, WKNavigationDelegate {
    let config : OEXConfig?
    weak var delegate : FindCoursesWebViewHelperDelegate?
    
    let webView : WKWebView = WKWebView()
    private var loadController = LoadStateViewController()
    
    private var request : NSURLRequest? = nil
    
    init(config : OEXConfig?, delegate : FindCoursesWebViewHelperDelegate?) {
        self.config = config
        self.delegate = delegate
        
        super.init()
        
        webView.navigationDelegate = self
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.allowsBackForwardNavigationGestures = true

        if let container = delegate?.containingControllerForWebViewHelper(self) {
            loadController.setupInController(container, contentView: webView)
            container.view.insertSubview(self.webView, atIndex: 0)
            
            self.webView.snp_makeConstraints { make in
                make.edges.equalTo(container.view)
            }
        }
    }
    
    private var courseInfoTemplate : String {
        return config?.courseEnrollmentConfig().webviewConfig.courseInfoURLTemplate ?? ""
    }
    
    var isWebViewLoaded : Bool {
        return self.loadController.state.isLoaded
    }
    
    func loadRequestWithURL(url : NSURL) {
        let request = NSURLRequest(URL: url)
        self.webView.loadRequest(request)
        self.request = request
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        let capturedLink = navigationAction.navigationType == .LinkActivated && (self.delegate?.webViewHelper(self, shouldLoadLinkWithRequest: request) ?? true)

        let outsideLink = (request.mainDocumentURL?.host != self.request?.URL?.host)
        if let URL = request.URL where outsideLink || capturedLink {
            UIApplication.sharedApplication().openURL(URL)
            decisionHandler(.Cancel)
            return
        }
        
        decisionHandler(.Allow)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        self.loadController.state = .Loaded
    }
    
    func showError(error : NSError) {
        let buttonInfo = MessageButtonInfo(title: Strings.retry) {[weak self] _ in
            if let request = self?.request {
                self?.webView.loadRequest(request)
                self?.loadController.state = .Initial
            }
        }
        self.loadController.state = LoadState.failed(error, buttonInfo: buttonInfo)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        showError(error)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        showError(error)
    }
    
    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if let credential = config?.URLCredentialForHost(challenge.protectionSpace.host) {
            completionHandler(.UseCredential, credential)
        }
        else {
            completionHandler(.PerformDefaultHandling, nil)
        }
    }
}
