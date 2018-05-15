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
    let searchBar = UISearchBar()
    private var loadController = LoadStateViewController()
    
    private var request : NSURLRequest? = nil
    var searchBaseURL: URL?
    let searchQuery:String?
    

    let bottomBar: UIView?
    
    init(config : OEXConfig?, delegate : FindCoursesWebViewHelperDelegate?, bottomBar: UIView?, showSearch: Bool, searchQuery: String?) {
        self.config = config
        self.delegate = delegate
        self.bottomBar = bottomBar
        self.searchQuery = searchQuery
        
        super.init()
        
        webView.navigationDelegate = self
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.accessibilityIdentifier = "find-courses-webview"

        if let container = delegate?.containingControllerForWebViewHelper(helper: self) {
            loadController.setupInController(controller: container, contentView: webView)

            let searchbarEnabled = (config?.courseEnrollmentConfig.webviewConfig.nativeSearchbarEnabled ?? false) && showSearch

            var webViewTop: ConstraintItem = container.safeTop
            var webViewBottom: ConstraintItem = container.safeBottom
            if searchbarEnabled {
                searchBar.delegate = self
                container.view.insertSubview(searchBar, at: 0)

                searchBar.snp.makeConstraints{ make in
                    make.leading.equalTo(container.safeLeading)
                    make.trailing.equalTo(container.safeTrailing)
                    make.top.equalTo(container.safeTop)
                }
                webViewTop = searchBar.snp.bottom
            }
            container.view.insertSubview(webView, at: 0)
            if let bar = bottomBar {
                container.view.insertSubview(bar, at: 0)
                bar.snp.makeConstraints { make in
                    make.leading.equalTo(container.safeLeading)
                    make.trailing.equalTo(container.safeTrailing)
                    make.bottom.equalTo(container.safeBottom)
                }
                webViewBottom = bar.snp.top
            }
            
            webView.snp.makeConstraints { make in
                make.leading.equalTo(container.safeLeading)
                make.trailing.equalTo(container.safeTrailing)
                make.bottom.equalTo(webViewBottom)
                make.top.equalTo(webViewTop)
            }
            
        }
    }


    private var courseInfoTemplate : String {
        return config?.courseEnrollmentConfig.webviewConfig.courseInfoURLTemplate ?? ""
    }
    
    var isWebViewLoaded : Bool {
        return self.loadController.state.isLoaded
    }

    public func load(withURL url: URL) {
        var discoveryURL = url
        if let searchQuery = searchQuery, let searchURL = searchBaseURL, let url = FindCoursesWebViewHelper.buildQuery(baseURL: searchURL.URLString, toolbarString: searchQuery) {
            discoveryURL = url
        }

        loadRequest(withURL: discoveryURL)
    }

    fileprivate func loadRequest(withURL url: URL) {
        let request = NSURLRequest(url: url)
        webView.load(request as URLRequest)
        self.request = request
    }

    private func showError(error : NSError) {
        let buttonInfo = MessageButtonInfo(title: Strings.reload) {[weak self] _ in
            if let request = self?.request {
                self?.webView.load(request as URLRequest)
                self?.loadController.state = .Initial
            }
        }
        self.loadController.state = LoadState.failed(error: error, buttonInfo: buttonInfo)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        let capturedLink = navigationAction.navigationType == .linkActivated && (self.delegate?.webViewHelper(helper: self, shouldLoadLinkWithRequest: request as NSURLRequest) ?? true)

        let outsideLink = (request.mainDocumentURL?.host != self.request?.url?.host)
        if let URL = request.url, outsideLink || capturedLink {
            UIApplication.shared.openURL(URL)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadController.state = .Loaded
        
        //Setting webView accessibilityValue for testing
        webView.evaluateJavaScript("document.getElementsByClassName('course-card')[0].innerText",
                                   completionHandler: { (result: Any?, error: Error?) in
                                    
                                    if (error == nil) {
                                        self.webView.accessibilityValue = "findCoursesLoaded"
                                    }
        })
        if let bar = bottomBar {
            bar.superview?.bringSubview(toFront: bar)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error: error as NSError)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error: error as NSError)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let credential = config?.URLCredentialForHost(challenge.protectionSpace.host as NSString) {
            completionHandler(.useCredential, credential)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

}

extension FindCoursesWebViewHelper: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let searchTerms = searchBar.text, let searchURL = searchBaseURL else { return }
        if let URL = FindCoursesWebViewHelper.buildQuery(baseURL: searchURL.URLString, toolbarString: searchTerms) {
            loadRequest(withURL: URL)
        }
    }

    @objc static func buildQuery(baseURL: String, toolbarString: String) -> URL? {
        let items = toolbarString.components(separatedBy: " ")
        let escapedItems = items.flatMap { $0.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)  }
        let searchTerm = "search_query=" + escapedItems.joined(separator: "+")
        let newQuery: String
        if baseURL.contains("?") {
            newQuery = baseURL + "&" + searchTerm
        } else {
            newQuery = baseURL + "?" + searchTerm

        }
        return URL(string: newQuery)
    }
}
