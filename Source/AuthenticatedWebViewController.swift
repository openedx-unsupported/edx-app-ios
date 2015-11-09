//
//  AuthenticatedWebViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import WebKit

class HeaderViewInsets : ContentInsetsSource {
    weak var insetsDelegate : ContentInsetsSourceDelegate?
    
    var view : UIView?
    
    var currentInsets : UIEdgeInsets {
        return UIEdgeInsets(top : view?.frame.size.height ?? 0, left : 0, bottom : 0, right : 0)
    }
    
    var affectsScrollIndicators : Bool {
        return false
    }
}

private protocol WebContentController {
    var view : UIView {get}
    var scrollView : UIScrollView {get}
    
    var alwaysRequiresOAuthUpdate : Bool { get}
    
    var initialContentState : AuthenticatedWebViewController.State { get }
    
    func loadURLRequest(request : NSURLRequest)
    
    func clearDelegate()
    func resetState()
}

private class WKWebViewContentController : WebContentController {
    private let webView = WKWebView(frame: CGRectZero)
    
    var view : UIView {
        return webView
    }
    
    var scrollView : UIScrollView {
        return webView.scrollView
    }
    
    func clearDelegate() {
        return webView.navigationDelegate = nil
    }
    
    func loadURLRequest(request: NSURLRequest) {
        webView.loadRequest(request)
    }
    
    func resetState() {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }
    
    var alwaysRequiresOAuthUpdate : Bool {
        return false
    }
    
    var initialContentState : AuthenticatedWebViewController.State {
        return AuthenticatedWebViewController.State.LoadingContent
    }
}

// Allows access to course content that requires authentication.
// Forwarding our oauth token to the server so we can get a web based cookie
public class AuthenticatedWebViewController: UIViewController, WKNavigationDelegate {
    
    private enum State {
        case CreatingSession
        case LoadingContent
        case NeedingSession
    }
    
    public struct Environment {
        public let config : OEXConfig?
        public let session : OEXSession?
        
        public init(config : OEXConfig?, session : OEXSession?) {
            self.config = config
            self.session = session
        }
    }
    
    private let environment : Environment
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    private let headerInsets : HeaderViewInsets
    
    private lazy var webController : WebContentController = {
        let controller = WKWebViewContentController()
        controller.webView.navigationDelegate = self
        return controller
    
    }()
    
    private var state = State.CreatingSession
    
    private var contentRequest : NSURLRequest? = nil
    
    public init(environment : Environment) {
        self.environment = environment
        
        loadController = LoadStateViewController()
        insetsController = ContentInsetsController()
        headerInsets = HeaderViewInsets()
        insetsController.addSource(headerInsets)
        
        super.init(nibName: nil, bundle: nil)
        
        automaticallyAdjustsScrollViewInsets = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Prevent crash due to stale back pointer, since WKWebView's UIScrollView apparently doesn't
        // use weak for its delegate
        webController.scrollView.delegate = nil
        webController.clearDelegate()
    }
    
    override public func viewDidLoad() {
        
        self.state = webController.initialContentState
        self.view.addSubview(webController.view)
        webController.view.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        self.loadController.setupInController(self, contentView: webController.view)
        webController.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        webController.scrollView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        self.insetsController.setupInController(self, scrollView: webController.scrollView)
        
        
        if let request = self.contentRequest {
            loadRequest(request)
        }
    }
    
    private func resetState() {
        loadController.state = .Initial
        state = .CreatingSession
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if view.window == nil {
            webController.resetState()
        }
        resetState()
    }
    
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
    
    public func showError(error : NSError?, icon : Icon? = nil, message : String? = nil) {
        loadController.state = LoadState.failed(error, icon : icon, message : message)
    }
    
    // MARK: Header View
    
    var headerView : UIView? {
        get {
            return headerInsets.view
        }
        set {
            headerInsets.view?.removeFromSuperview()
            headerInsets.view = newValue
            if let headerView = newValue {
                webController.view.addSubview(headerView)
                headerView.snp_makeConstraints {make in
                    if #available(iOS 9.0, *) {
                        make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                    }
                    else {
                        make.top.equalTo(self.snp_topLayoutGuideBottom)
                    }
                    make.leading.equalTo(webController.view)
                    make.trailing.equalTo(webController.view)
                }
                webController.view.setNeedsLayout()
                webController.view.layoutIfNeeded()
            }
        }
    }
    
    private func loadOAuthRefreshRequest() {
        if let hostURL = environment.config?.apiHostURL() {
            let URL = hostURL.URLByAppendingPathComponent("/oauth2/login/")
            let exchangeRequest = NSMutableURLRequest(URL: URL)
            exchangeRequest.HTTPMethod = HTTPMethod.POST.rawValue
            
            for (key, value) in self.environment.session?.authorizationHeaders ?? [:] {
                exchangeRequest.addValue(value, forHTTPHeaderField: key)
            }
            self.webController.loadURLRequest(exchangeRequest)
        }
    }
    
    // MARK: Request Loading
    
    public func loadRequest(request : NSURLRequest) {
        contentRequest = request
        loadController.state = .Initial
        state = webController.initialContentState
        
        if webController.alwaysRequiresOAuthUpdate {
            loadOAuthRefreshRequest()
        }
        else {
            webController.loadURLRequest(request)
        }
    }
    
    // MARK: WKWebView delegate
    
    public func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .LinkActivated, .FormSubmitted, .FormResubmitted:
            if let URL = navigationAction.request.URL {
                UIApplication.sharedApplication().openURL(URL)
            }
            decisionHandler(.Cancel)
        default:
            decisionHandler(.Allow)
        }
    }
    
    public func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        
        if let
        httpResponse = navigationResponse.response as? NSHTTPURLResponse,
        statusCode = OEXHTTPStatusCode(rawValue: httpResponse.statusCode),
        errorGroup = statusCode.errorGroup
            where state == .LoadingContent
        {
            switch errorGroup {
            case .Http4xx:
                self.state = .NeedingSession
            case .Http5xx:
                self.loadController.state = LoadState.failed()
                decisionHandler(.Cancel)
            }
        }
        decisionHandler(.Allow)
        
    }
    
    public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        switch state {
        case .CreatingSession:
            if let request = contentRequest {
                state = .LoadingContent
                webController.loadURLRequest(request)
            }
            else {
                loadController.state = LoadState.failed()
            }
        case .LoadingContent:
            loadController.state = .Loaded
        case .NeedingSession:
            state = .CreatingSession
            loadOAuthRefreshRequest()
        }
    }
    
    public func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        showError(error)
    }
    
    public func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        showError(error)
    }
    
    public func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if let credential = environment.config?.URLCredentialForHost(challenge.protectionSpace.host) {
            completionHandler(.UseCredential, credential)
        }
        else {
            completionHandler(.PerformDefaultHandling, nil)
        }
    }

}

