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

private class UIWebViewContentController : WebContentController {
    private let webView = UIWebView(frame: CGRectZero)
    
    var view : UIView {
        return webView
    }
    
    var scrollView : UIScrollView {
        return webView.scrollView
    }
    
    func clearDelegate() {
        return webView.delegate = nil
    }

    func loadURLRequest(request: NSURLRequest) {
        webView.loadRequest(request)
    }
    
    func resetState() {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }
    
    var alwaysRequiresOAuthUpdate : Bool {
        return true
    }
    
    var initialContentState : AuthenticatedWebViewController.State {
        return AuthenticatedWebViewController.State.CreatingSession
    }
    
    
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
public class AuthenticatedWebViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, WKNavigationDelegate {
    
    private enum State {
        case CreatingSession
        case LoadingContent
        case NeedingSession
    }
    
    public struct Environment {
        public let config : OEXConfig?
        public let session : OEXSession?
        public let styles : OEXStyles?
        
        public init(config : OEXConfig?, session : OEXSession?, styles : OEXStyles?) {
            self.config = config
            self.session = session
            self.styles = styles
        }
    }
    
    private let environment : Environment
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    private let headerInsets : HeaderViewInsets
    
    // After we drop support for iOS7, we can just always use WKWebView
    private lazy var webController : WebContentController = {
        // Temporarily disable the WKWebView version while we figure out why we're not sending a
        // a meta name="viewport" tag. See https://openedx.atlassian.net/browse/MA-960
//        if NSClassFromString("WKWebView") != nil {
//            let controller = WKWebViewContentController()
//            controller.webView.navigationDelegate = self
//            return controller
//        }
//        else {
            let controller = UIWebViewContentController()
            controller.webView.delegate = self
            return controller
//        }
        
    }()
    
    private var state = State.CreatingSession
    
    private var contentRequest : NSURLRequest? = nil
    
    public init(environment : Environment) {
        self.environment = environment
        
        loadController = LoadStateViewController(styles: self.environment.styles)
        insetsController = ContentInsetsController()
        headerInsets = HeaderViewInsets()
        insetsController.addSource(headerInsets)
        
        super.init(nibName: nil, bundle: nil)
        
        automaticallyAdjustsScrollViewInsets = false
    }
    
    required public init(coder aDecoder: NSCoder) {
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
        webController.view.backgroundColor = self.environment.styles?.standardBackgroundColor()
        webController.scrollView.backgroundColor = self.environment.styles?.standardBackgroundColor()
        webController.scrollView.delegate = self
        
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
        loadController.state = LoadState.failed(error : error, icon : icon, message : message)
    }
    
    // MARK: Header View
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        // Ideally we'd just add the header view directly to the webview's .scrollview,
        // and then we would get scrolling with the content for free
        // but that totally screwed up leading/trailing constraints for a label
        // inside a UIWebView, so we go this route instead
        
        headerInsets.view?.transform = CGAffineTransformMakeTranslation(0, -(scrollView.contentInset.top + scrollView.contentOffset.y))
    }

    
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
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                    make.leading.equalTo(webController.view)
                    make.trailing.equalTo(webController.view)
                }
                webController.view.setNeedsLayout()
                webController.view.layoutIfNeeded()
            }
        }
    }
    
    var apiHostURL : String {
        return environment.config?.apiHostURL() ?? ""
    }
    
    private func loadOAuthRefreshRequest() {
        NSURL(string:apiHostURL + "/oauth2/login/").map { URL -> Void in
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
            navigationAction.request.URL.map { UIApplication.sharedApplication().openURL($0) }
            decisionHandler(.Cancel)
        default:
            decisionHandler(.Allow)
        }
    }
    
    public func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        
        let continueAction : () -> Void = {
            self.state = .LoadingContent
            decisionHandler(.Allow)
        }
        
        if let httpResponse = navigationResponse.response as? NSHTTPURLResponse,
            statusCode = OEXHTTPStatusCode(rawValue: httpResponse.statusCode)
            where state == .LoadingContent
        {
            if statusCode.is4xx {
                decisionHandler(.Cancel)
                loadOAuthRefreshRequest()
                state = .NeedingSession
            }
            else {
                continueAction()
            }
        }
        else {
            continueAction()
        }
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
    
    // MARK: UIWebView delegate
    
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked || navigationType == .FormSubmitted {
            request.URL.map { UIApplication.sharedApplication().openURL($0) }
            return false
        }
        return true
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
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
            loadOAuthRefreshRequest()
            state = .CreatingSession
        }
    }
    
    public func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        showError(error)
    }
}

