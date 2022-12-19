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
    var isLoading: Bool {get}
    
    var alwaysRequiresOAuthUpdate : Bool { get}
    
    var initialContentState : AuthenticatedWebViewController.State { get }
    
    func loadURLRequest(request : NSURLRequest)
    func resetState()
}

@objc protocol WebViewNavigationDelegate: AnyObject {
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool
    func webViewContainingController() -> UIViewController
}

// A class should implement AlwaysRequireAuthenticationOverriding protocol if it always require authentication.
// This will ignore the WebviewCookiesManager session and make a new /oauth2/login/ request within the webview
// In normal cases this shouldn't be implemented
protocol AuthenticatedWebViewControllerRequireAuthentication {
    func alwaysRequireAuth() -> Bool
}

protocol AuthenticatedWebViewControllerDelegate: AnyObject {
    func authenticatedWebViewController(authenticatedController: AuthenticatedWebViewController, didFinishLoading webview: WKWebView)
}

@objc protocol AJAXCompletionCallbackDelegate: AnyObject {
    func didCompletionCalled(completion: Bool)
}

protocol WebViewNavigationResponseDelegate: AnyObject {
    func handleHttpStatusCode(statusCode: OEXHTTPStatusCode) -> Bool
}

private class WKWebViewContentController : WebContentController {
    fileprivate let webView: WKWebView

    var view : UIView {
        return webView
    }

    var scrollView : UIScrollView {
        return webView.scrollView
    }
    
    init(configuration: WKWebViewConfiguration) {
        webView = WKWebView(frame: .zero, configuration: configuration)
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

    var isLoading: Bool {
        return webView.isLoading
    }
}

private let OAuthExchangePath = "/oauth2/login/"

fileprivate let AJAXCallBackHandler = "ajaxCallbackHandler"
fileprivate let ajaxScriptFile = "ajaxHandler"
// Allows access to course content that requires authentication.
// Forwarding our oauth token to the server so we can get a web based cookie
public class AuthenticatedWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    fileprivate enum xBlockCompletionCallbackType: String {
        case html = "publish_completion"
        case problem = "problem_check"
        case dragAndDrop = "do_attempt"
        case ora = "render_grade"
    }
    
    fileprivate enum State {
        case CreatingSession
        case LoadingContent
        case NeedingSession
    }

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & ReachabilityProvider & NetworkManagerProvider
    weak var delegate: AuthenticatedWebViewControllerDelegate?
    internal let environment : Environment
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    private let headerInsets : HeaderViewInsets
    weak var webViewDelegate: WebViewNavigationDelegate?
    weak var ajaxCallbackDelegate: AJAXCompletionCallbackDelegate?
    weak var webViewNavigationResponseDelegate: WebViewNavigationResponseDelegate?
    private lazy var configurations = environment.config.webViewConfiguration()
    private let cookiesManager = WebviewCookiesManager.shared
    
    private var shouldListenForAjaxCallbacks = false
    
    private lazy var webController: WebContentController = {
        let controller = WKWebViewContentController(configuration: configurations)
        if shouldListenForAjaxCallbacks {
            addAjaxCallbackScript(in: configurations.userContentController)
        }
        controller.webView.navigationDelegate = self
        controller.webView.uiDelegate = self
        return controller

    }()
    
    var scrollView: UIScrollView {
        return webController.scrollView
    }
    
    private var state = State.CreatingSession
    
    private var contentRequest : NSURLRequest? = nil
    var currentUrl: NSURL? {
        return contentRequest?.url as NSURL?
    }
    
    public func setLoadControllerState(withState state: LoadState) {
        loadController.state = state
    }
    
    public init(environment : Environment, shouldListenForAjaxCallbacks: Bool = false) {
        self.environment = environment
        self.shouldListenForAjaxCallbacks = shouldListenForAjaxCallbacks
        
        loadController = LoadStateViewController()
        insetsController = ContentInsetsController()
        headerInsets = HeaderViewInsets()
        insetsController.addSource(source: headerInsets)
        
        super.init(nibName: nil, bundle: nil)
        scrollView.contentInsetAdjustmentBehavior = .automatic
        webController.view.accessibilityIdentifier = "AuthenticatedWebViewController:authenticated-web-view"
        addObservers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Prevent crash due to stale back pointer, since WKWebView's UIScrollView apparently doesn't
        // use weak for its delegate
        webController.scrollView.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        state = webController.initialContentState
        view.addSubview(webController.view)
        webController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        loadController.setupInController(controller: self, contentView: webController.view)
        webController.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        webController.scrollView.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        insetsController.setupInController(owner: self, scrollView: webController.scrollView)
        
        if let request = contentRequest {
            loadRequest(request: request)
        }
    }

    private func addObservers() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_DYNAMIC_TEXT_TYPE_UPDATE) { (_, observer, _) in
            observer.reload()
        }

        NotificationCenter.default.oex_addObserver(observer: self, name: WebviewCookiesCreatedNotification) { (_, observer, _) in
            if observer.cookiesManager.cookiesState == .failed {
                observer.showError(with: .failed())
            }
            else {
                observer.syncCookiesStorage()
            }
        }
    }

    // Sync cookies between HTTPCookieStorage and WKHTTPCookieStore
    private func syncCookiesStorage() {
        let cookies = HTTPCookieStorage.shared.cookies
        DispatchQueue.global().async { [weak self] in
            self?.logTestAnalayticsForCrash(name: "TestEvent: syncing cookies")
            let semaphore = DispatchSemaphore(value: 0)
            for cookie in cookies ?? [] {
                if let webview = self?.webController.view as? WKWebView {
                    DispatchQueue.main.async {
                        webview.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                            semaphore.signal()
                        }
                    }
                }
                semaphore.wait()
            }
            DispatchQueue.main.async {
                self?.cookiesManager.updateSessionState(state: .created)
                self?.reload()
                self?.logTestAnalayticsForCrash(name: "TestEvent: cookies synced")
            }
        }
    }

    private func logTestAnalayticsForCrash(name: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = name;
        let info = [
            "loaded_url": contentRequest?.url?.absoluteString ?? "",
            "token_status": environment.networkManager.tokenStatus.rawValue
        ] as [String : Any]

        environment.analytics.trackEvent(event, forComponent: nil, withInfo: info)
    }

    private func addAjaxCallbackScript(in contentController: WKUserContentController) {
        guard let url = Bundle.main.url(forResource: ajaxScriptFile, withExtension: "js"),
              let handler = try? String(contentsOf: url, encoding: .utf8) else { return }
        let script = WKUserScript(source: handler, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.add(self, name: AJAXCallBackHandler)
        contentController.addUserScript(script)
    }
    
    public func reload() {
        guard let request = contentRequest, !webController.isLoading else { return }

        state = .LoadingContent
        loadRequest(request: request)
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
        if headerView != nil {
            insetsController.updateInsets()
        }
    }
    
    public func showError(error : NSError?, icon : Icon? = nil, message : String? = nil) {
        let buttonInfo = MessageButtonInfo(title: Strings.reload) {[weak self] in
            if let request = self?.contentRequest, self?.environment.reachability.isReachable() ?? false {
                self?.loadController.state = .Initial
                self?.webController.loadURLRequest(request: request)
            }
        }
        loadController.state = LoadState.failed(error: error, icon: icon, message: message, buttonInfo: buttonInfo)
        refreshAccessibility()
    }
    
    public func showError(with state: LoadState) {
        loadController.state = state
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
                headerView.snp.makeConstraints { make in
                    make.top.equalTo(safeTop)
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
            UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
        }
    }
    
    // MARK: Request Loading
    
    public func loadRequest(request : NSURLRequest) {
        contentRequest = request
        var ignoreCookiesManager = webController.alwaysRequiresOAuthUpdate
        if let parent = parent as? AuthenticatedWebViewControllerRequireAuthentication {
            ignoreCookiesManager = parent.alwaysRequireAuth()
        }

        if cookiesManager.cookiesExpired && !ignoreCookiesManager {
            if cookiesManager.cookiesState != .creating && cookiesManager.cookiesState != .sync {
                cookiesManager.createOrUpdateCookies(environment: environment)
            }
            return
        }

        loadController.state = .Initial
        state = webController.initialContentState

        if ignoreCookiesManager {
            state = State.CreatingSession
            loadOAuthRefreshRequest()
        }
        else {
            webController.loadURLRequest(request: request)
        }
    }
    
    // MARK: WKWebView delegate

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let isWebViewDelegateHandled = !(webViewDelegate?.webView(webView, shouldLoad: navigationAction.request) ?? true)
        if isWebViewDelegateHandled {
            decisionHandler(.cancel)
        } else {
            switch navigationAction.navigationType {
            case .linkActivated:
                if let url = navigationAction.request.url, UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                decisionHandler(.cancel)
            default:
                decisionHandler(.allow)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if let httpResponse = navigationResponse.response as? HTTPURLResponse, let statusCode = OEXHTTPStatusCode(rawValue: httpResponse.statusCode), let errorGroup = statusCode.errorGroup, state == .LoadingContent {
            
            if webViewNavigationResponseDelegate?.handleHttpStatusCode(statusCode: statusCode) ?? false {
                decisionHandler(.cancel)
                return
            }
            
            switch errorGroup {
            case .http4xx:
                state = .NeedingSession
                break
            case .http5xx:
                loadController.state = LoadState.failed()
                decisionHandler(.cancel)
                return
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
            if cookiesManager.cookiesState != .creating && cookiesManager.cookiesState != .sync {
                cookiesManager.createOrUpdateCookies(environment: environment)
            }
        }
        
        refreshAccessibility()
    }

    /* Completion callbacks in case of different xBlocks
     HTML /publish_completion
     Video /publish_completion
     Problem problem_check
     DragAndDrop handler/do_attempt
     ORABlock responseText contains class 'is--complete'
     */
    
    private func isCompletionCallback(with data: Dictionary<AnyHashable, Any>) -> Bool {
        let callback = AJAXCallbackData(data: data)
        let requestURL = callback.url
        
        if callback.statusCode != OEXHTTPStatusCode.code200OK.rawValue {
            return false
        }
        
        if isBlockOf(type: .ora, with: requestURL) {
            return callback.responseText.contains("is--complete")
        } else {
            return isBlockOf(type: .html, with: requestURL)
                || isBlockOf(type: .problem, with: requestURL)
                || isBlockOf(type: .dragAndDrop, with: requestURL)
        }
    }
    
    private func isBlockOf(type: xBlockCompletionCallbackType, with requestURL: String) -> Bool {
        return requestURL.contains(type.rawValue)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == AJAXCallBackHandler {
            guard let data = message.body as? Dictionary<AnyHashable, Any> else { return }
            
            if isCompletionCallback(with: data) {
                ajaxCallbackDelegate?.didCompletionCalled(completion: true)
            }
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error: error as NSError?)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard !loadController.state.isError else { return }
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
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: { action in
            completionHandler(true)
        }))
        
        alertController.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: { action in
            completionHandler(false)
        }))
        
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = view
            presenter.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        if isViewVisible {
            present(alertController, animated: true, completion: nil)
        } else {
            completionHandler(false)
        }
    }
}

private struct AJAXCallbackData {
    private enum Keys: String {
        case url = "url"
        case statusCode = "status"
        case responseText = "response_text"
    }
    
    let url: String
    let statusCode: Int
    let responseText: String

    init(data: Dictionary<AnyHashable, Any>) {
        url = data[Keys.url.rawValue] as? String ?? ""
        statusCode = data[Keys.statusCode.rawValue] as? Int ?? 0
        responseText = data[Keys.responseText.rawValue] as? String ?? ""
    }
}
