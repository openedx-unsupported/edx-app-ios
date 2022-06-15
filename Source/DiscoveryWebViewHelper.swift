//
//  DiscoveryWebViewHelper.swift
//  edX
//
//  Created by Akiva Leffert on 11/9/15.
//  Copyright © 2015-2016 edX. All rights reserved.
//

import UIKit
import WebKit

fileprivate enum QueryParameterKeys {
    static let searchQuery = "q"
    static let subject = "subject"
}

class DiscoveryWebViewHelper: NSObject {
    
    typealias Environment = OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXSessionProvider
    fileprivate let environment: Environment
    weak var delegate: WebViewNavigationDelegate?
    fileprivate let contentView = UIView()
    fileprivate let webView: WKWebView
    fileprivate var loadController = LoadStateViewController()
    fileprivate let refreshController = PullRefreshController()
    
    fileprivate var request: URLRequest? = nil
    @objc var baseURL: URL?
    fileprivate let searchQuery:String?
    let bottomBar: UIView?
    private var urlObservation: NSKeyValueObservation?
    fileprivate var params: [String: String]? {
        return (webView.url as NSURL?)?.oex_queryParameters() as? [String : String]
    }
    
    private var bottomSpace: CGFloat {
        //TODO: this should be the height of bottomBar but for now giving it static value as the NSCopying making new object's frame as zero
        return 90
    }
    
    @objc convenience init(environment: Environment, delegate: WebViewNavigationDelegate?, bottomBar: UIView?) {
        self.init(environment: environment, delegate: delegate, bottomBar: bottomBar, searchQuery: nil)
    }
    
    @objc init(environment: Environment, delegate: WebViewNavigationDelegate?, bottomBar: UIView?, searchQuery: String?) {
        self.environment = environment
        self.webView = WKWebView(frame: .zero, configuration: environment.config.webViewConfiguration())
        self.delegate = delegate
        self.bottomBar = bottomBar
        self.searchQuery = searchQuery
        super.init()
        webView.disableZoom()
        webView.navigationDelegate = self
        webView.scrollView.decelerationRate = UIScrollView.DecelerationRate.normal
        webView.accessibilityIdentifier = "find-courses-webview"
        guard let container = delegate?.webViewContainingController() else { return }
        container.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(container.safeEdges)
        }
        loadController.setupInController(controller: container, contentView: contentView)
        refreshController.setupInScrollView(scrollView: webView.scrollView)
        refreshController.delegate = self
        refreshView()
    }
    
    @objc func refreshView() {
        guard let _ = delegate?.webViewContainingController() else { return }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let isUserLoggedIn = environment.session.currentUser != nil

        contentView.addSubview(webView)
        if let bar = bottomBar, !isUserLoggedIn {
            contentView.addSubview(bar)
            bar.snp.makeConstraints { make in
                make.leading.equalTo(contentView)
                make.trailing.equalTo(contentView)
                make.bottom.equalTo(contentView)
            }
        }

        webView.snp.makeConstraints { make in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
            make.top.equalTo(contentView)
            if !isUserLoggedIn {
                make.bottom.equalTo(contentView).offset(-bottomSpace)
            }
            else {
                make.bottom.equalTo(contentView)
            }
        }

        addObserver()
    }
    
    private func addObserver() {
        // Add URL change oberver on webview, so URL change of webview can be tracked and handled.
        urlObservation = webView.observe(\.url, changeHandler: { [weak self] (webView, change) in
            self?.handleURLChangeNotification()
        })
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_DYNAMIC_TEXT_TYPE_UPDATE) { (_, observer, _) in
            observer.reload()
        }
    }
    
    private func handleURLChangeNotification() {
    }
    
    private var URLHasSearchFilter: Bool {
        guard let URL = webView.url?.absoluteString else { return false }
        
        return URL.contains(find: QueryParameterKeys.searchQuery)
    }

    private func reload(showLoadingScreen: Bool = true) {
        guard let URL = webView.url, !webView.isLoading else { return }
        
        if showLoadingScreen {
            loadController.state = .Initial
        }
        loadRequest(withURL: URL)
    }
    
    private var isiPhoneAndVerticallyCompact: Bool {
        guard let container = delegate?.webViewContainingController() else { return false }
        return container.isVerticallyCompact() && UIDevice.current.userInterfaceIdiom == .phone
    }
    
    private var isWebViewQueriedSubject: Bool {
        guard let url = webView.url?.absoluteString else { return false }
        return url.contains(find: "\(QueryParameterKeys.subject)=")
    }

    private var courseInfoTemplate : String {
        return environment.config.discovery.webview.courseDetailTemplate ?? ""
    }
    
    var isWebViewLoaded : Bool {
        return self.loadController.state.isLoaded
    }

    @objc public func load(withURL url: URL) {
        var discoveryURL = url
        
        if let baseURL = baseURL, let searchQuery = searchQuery {
            var params = self.params ?? [:]
            set(value: searchQuery, for: QueryParameterKeys.searchQuery, in: &params)
            if let url = DiscoveryWebViewHelper.buildQuery(baseURL: baseURL.URLString, params: params) {
                discoveryURL = url
            }
        }

        loadRequest(withURL: discoveryURL)
    }
    
    fileprivate func set(value: String, for key: String, in params: inout [String: String]) {
        params[key] = value.addingPercentEncodingForRFC3986
    }

    fileprivate func loadRequest(withURL url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
        self.request = request
    }

    fileprivate func showError(error : NSError) {
        let buttonInfo = MessageButtonInfo(title: Strings.reload) {[weak self] in
            if let request = self?.request {
                self?.webView.load(request as URLRequest)
                self?.loadController.state = .Initial
            }
        }
        self.loadController.state = LoadState.failed(error: error, buttonInfo: buttonInfo)
    }
    
    deinit {
        urlObservation?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension DiscoveryWebViewHelper: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        
        let isWebViewDelegateHandled = !(delegate?.webView(webView, shouldLoad: request) ?? true)
        if isWebViewDelegateHandled {
            decisionHandler(.cancel)
        } else {
            let capturedLink = navigationAction.navigationType == .linkActivated
            let outsideLink = (request.mainDocumentURL?.host != self.request?.url?.host)
            if let url = request.url, outsideLink || capturedLink {
                guard let contrller = delegate?.webViewContainingController(), UIApplication.shared.canOpenURL(url) else { return }
                environment.analytics.trackEvent(with: .DiscoverExternalLinkOpenAlert, name: .DiscoverExternalLinkOpenAlert, category: .Discovery, info: ["url" : url.absoluteString])
                let alertController = UIAlertController().showAlert(withTitle: Strings.leavingAppTitle, message: Strings.leavingAppMessage(platformName: environment.config.platformName()), cancelButtonTitle: nil, onViewController: contrller) { _, _, _ in }

                alertController.addButton(withTitle: Strings.cancel, style: .cancel) { [weak self] _ in
                    self?.environment.analytics.trackEvent(with: .DiscoverExternalLinkOpenAlertAction, name: .DiscoverExternalLinkOpenAlertAction, category: .Discovery, info: ["url" : url.absoluteString, "alert_action": "cancel"])
                }

                alertController.addButton(withTitle: Strings.continueText, style: .default) { [weak self] _ in
                    self?.environment.analytics.trackEvent(with: .DiscoverExternalLinkOpenAlertAction, name: .DiscoverExternalLinkOpenAlertAction, category: .Discovery, info: ["url" : url.absoluteString, "alert_action": "continue"])
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadController.state = .Loaded
        refreshController.endRefreshing()
        if let bar = bottomBar {
            bar.superview?.bringSubviewToFront(bar)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error: error as NSError)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error: error as NSError)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let credential = environment.config.URLCredentialForHost(challenge.protectionSpace.host as NSString) {
            completionHandler(.useCredential, credential)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension DiscoveryWebViewHelper: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.isEmpty,
            webView.url != baseURL,
            let baseURL = baseURL,
            var params = params, params[QueryParameterKeys.searchQuery] != nil else { return }

        removeParam(for: QueryParameterKeys.searchQuery, in: &params)

        if let URL = DiscoveryWebViewHelper.buildQuery(baseURL: baseURL.URLString, params: params) {
            loadRequest(withURL: URL)
        }
    }

    private func removeParam(for key: String, in params: inout [String: String]) {
        params.removeValue(forKey: key)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        var action = "landing_screen"
        if let _ = environment.session.currentUser {
            action = "discovery_tab"
        }
        environment.analytics.trackCourseSearch(search: searchBar.text ?? "", action: action)
        guard let searchText = searchBar.text,
            let baseURL = baseURL,
            var params = params else { return }
        set(value: searchText, for: QueryParameterKeys.searchQuery, in: &params)
        if let URL = DiscoveryWebViewHelper.buildQuery(baseURL: baseURL.URLString, params: params) {
            loadController.state = .Initial
            loadRequest(withURL: URL)
        }
    }
    
    static func buildQuery(baseURL: String, params: [String: String]) -> URL? {
        var query = baseURL
        for param in params {
            let join = query.contains("?") ? "&" : "?"
            let value = param.key + "=" + param.value
            if !query.contains(find: value) {
                query = query + join + value
            }
        }
        
        return URL(string: query)
    }
    
}

extension DiscoveryWebViewHelper: PullRefreshControllerDelegate {
    func refreshControllerActivated(controller: PullRefreshController) {
        reload(showLoadingScreen: false)
    }
}

extension DiscoveryWebViewHelper {
    @objc var t_webView: WKWebView {
        return webView
    }
}

extension String {
    //  Section 2.3 of RFC 3986 lists the characters that you should not percent encode as they have no special meaning in a URL:
    //
    //  ALPHA / DIGIT / “-” / “.” / “_” / “~”
    //
    //  Section 3.4 also explains that since a query will often itself include a URL it is preferable to not percent encode the slash (“/”) and question mark (“?”)
    
    var addingPercentEncodingForRFC3986: String {
        let unreserved = "-._~/?"
        var allowed: CharacterSet = .alphanumerics
        allowed.insert(charactersIn: unreserved)
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }
    
}

extension WKWebView {
     func disableZoom() {
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" +
            "head.appendChild(meta);"

        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(script)
    }
}
