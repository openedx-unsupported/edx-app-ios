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
        return true
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

// A class should implement AlwaysRequireAuthenticationOverriding protocol if it always require authentication.
protocol AuthenticatedWebViewControllerRequireAuthentication {
}

protocol AuthenticatedWebViewControllerDelegate {
    func authenticatedWebViewController(authenticatedController: AuthenticatedWebViewController, didFinishLoading webview: WKWebView)
}

private class WKWebViewContentController : WebContentController {
    fileprivate let webView = WKWebView(frame: CGRect.zero)
    
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
        webView.load(request as URLRequest)
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

private let OAuthExchangePath = "/oauth2/login/"

// Allows access to course content that requires authentication.
// Forwarding our oauth token to the server so we can get a web based cookie
public class AuthenticatedWebViewController: UIViewController, WKNavigationDelegate {
    
    fileprivate enum State {
        case CreatingSession
        case LoadingContent
        case NeedingSession
    }

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider
    var delegate: AuthenticatedWebViewControllerDelegate?
    internal let environment : Environment
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
    var currentUrl: NSURL? {
        return contentRequest?.url as NSURL?
    }
    
    public func setLoadControllerState(withState state: LoadState) {
        loadController.state = state
    }
    
    public init(environment : Environment) {
        self.environment = environment
        
        loadController = LoadStateViewController()
        insetsController = ContentInsetsController()
        headerInsets = HeaderViewInsets()
        insetsController.addSource(source: headerInsets)
        
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
        self.loadController.setupInController(controller: self, contentView: webController.view)
        webController.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        webController.scrollView.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        self.insetsController.setupInController(owner: self, scrollView: webController.scrollView)
        
        
        if let request = self.contentRequest {
            loadRequest(request: request)
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
        loadController.state = LoadState.failed(error: error, icon : icon, message : message)
        refreshAccessibility()
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
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                    make.leading.equalTo(webController.view)
                    make.trailing.equalTo(webController.view)
                }
                webController.view.setNeedsLayout()
                webController.view.layoutIfNeeded()
            }
        }
    }
    
    private func loadOAuthRefreshRequest() {
        if let hostURL = environment.config.apiHostURL() {
            let URL = hostURL.appendingPathComponent(OAuthExchangePath)
            let exchangeRequest = NSMutableURLRequest(url: URL)
            exchangeRequest.httpMethod = HTTPMethod.POST.rawValue
            
            for (key, value) in self.environment.session.authorizationHeaders {
                exchangeRequest.addValue(value, forHTTPHeaderField: key)
            }
            self.webController.loadURLRequest(request: exchangeRequest)
        }
    }
    
    private func refreshAccessibility() {
        DispatchQueue.main.async {
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
        }
    }
    
    // MARK: Request Loading
    
    public func loadRequest(request : NSURLRequest) {
        contentRequest = request
        loadController.state = .Initial
        state = webController.initialContentState
        
        let isAuthRequestRequire = ((parent as? AuthenticatedWebViewControllerRequireAuthentication) != nil) ? true: webController.alwaysRequiresOAuthUpdate

        if isAuthRequestRequire {
            self.state = State.CreatingSession
            loadOAuthRefreshRequest()
        }
        else {
            webController.loadURLRequest(request: request)
        }
    }
    
    // MARK: WKWebView delegate

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated, .formSubmitted, .formResubmitted:
            if let URL = navigationAction.request.url {
                UIApplication.shared.openURL(URL)
            }
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if let httpResponse = navigationResponse.response as? HTTPURLResponse, let statusCode = OEXHTTPStatusCode(rawValue: httpResponse.statusCode), let errorGroup = statusCode.errorGroup, state == .LoadingContent {
            
            switch errorGroup {
            case HttpErrorGroup.http4xx:
                self.state = .NeedingSession
            case HttpErrorGroup.http5xx:
                self.loadController.state = LoadState.failed()
                decisionHandler(.cancel)
            }
        }
        decisionHandler(.allow)
        
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        switch state {
        case .CreatingSession:
            if let request = contentRequest {
                state = .LoadingContent
                webController.loadURLRequest(request: request)
                
            }
            else {
                loadController.state = LoadState.failed()
            }
        case .LoadingContent:
            //The class which will implement this protocol method will be responsible to set the loadController state as Loaded
            if delegate?.authenticatedWebViewController(authenticatedController: self, didFinishLoading: webView) == nil {
              loadController.state = .Loaded
            }
        case .NeedingSession:
            state = .CreatingSession
            loadOAuthRefreshRequest()
        }
        
        refreshAccessibility()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error: error as NSError?)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error: error as NSError?)
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Don't use basic auth on exchange endpoint. That is explicitly non protected
        // and it screws up the authorization headers
        if let URL = webView.url, ((URL.absoluteString.hasSuffix(OAuthExchangePath)) != false) {
            completionHandler(.performDefaultHandling, nil)
        }
        else if let credential = environment.config.URLCredentialForHost(challenge.protectionSpace.host as NSString)  {
            completionHandler(.useCredential, credential)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

}

