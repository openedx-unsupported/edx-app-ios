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
    var searchBaseURL: NSURL?

    let thing =  UIView()
    
    init(config : OEXConfig?, delegate : FindCoursesWebViewHelperDelegate?) {
        self.config = config
        self.delegate = delegate
        
        super.init()
        
        webView.navigationDelegate = self
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.accessibilityIdentifier = "find-courses-webview"

        if let container = delegate?.containingControllerForWebViewHelper(self) {
            loadController.setupInController(container, contentView: webView)

            let searchbarEnabled = config?.courseEnrollmentConfig.webviewConfig.nativeSeachbarEnabled ?? false

            let webviewTop: ConstraintItem
            if searchbarEnabled {
                searchBar.delegate = self

                container.view.insertSubview(searchBar, atIndex: 0)

                searchBar.snp_makeConstraints{ make in
                    make.leading.equalTo(container.view)
                    make.trailing.equalTo(container.view)
                    make.top.equalTo(container.view)
                }
                webviewTop = searchBar.snp_bottom
            } else {
                webviewTop = container.view.snp_top
            }


            container.view.insertSubview(webView, atIndex: 0)

            webView.snp_makeConstraints { make in
                make.leading.equalTo(container.view)
                make.trailing.equalTo(container.view)
                make.bottom.equalTo(container.view)
                make.top.equalTo(webviewTop)
            }

            thing.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.65)
            container.view.insertSubview(thing, atIndex: 0)
            thing.snp_makeConstraints(closure: { (make) in
                make.height.equalTo(50)
                make.leading.equalTo(container.view)
                make.trailing.equalTo(container.view)
                make.bottom.equalTo(container.view)
            })

            setupBottomButtons(thing)
        }
    }

    private func setupBottomButtons(bottomButtons: UIView) {
//        bottomButtons.distribution = TZStackViewDistribution.EqualCentering
//        bottomButtons.axis = .Horizontal
//        bottomButtons.spacing = 40
//        

        let signInButton = UIButton()
        signInButton.applyButtonStyle(OEXStyles.sharedStyles().filledButtonStyle(OEXStyles.sharedStyles().primaryBaseColor()), withTitle: "Sign in")
        signInButton.oex_addAction({ [weak self] _ in
//            self?.showLogin()
            }, forEvents: .TouchUpInside)

        let signUpButton = UIButton()
        signUpButton.applyButtonStyle(OEXStyles.sharedStyles().filledButtonStyle(OEXStyles.sharedStyles().secondaryBaseColor()), withTitle: "Sign up")
        signUpButton.oex_addAction({ [weak self] _ in
//            self?.showRegistration()
            }, forEvents: .TouchUpInside)

        bottomButtons.addSubview(signInButton)
        bottomButtons.addSubview(signUpButton)

        signInButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(bottomButtons)
            make.leading.equalTo(bottomButtons).inset(30)
            make.width.equalTo(120)
        }

        signUpButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(bottomButtons)
            make.trailing.equalTo(bottomButtons).inset(30)
            make.width.equalTo(signInButton)
        }

//
//        bottomButtons.addArrangedSubview(signUpButton)
//        bottomButtons.addArrangedSubview(signInButton)

//        view.addSubview(bottomButtons)
//        bottomButtons.snp_makeConstraints { (make) in
//            make.bottom.equalTo(view).inset(15)
//            make.leading.equalTo(view.snp_leading).offset(30)
//            make.trailing.equalTo(view.snp_trailing).inset(30)
//        }
    }
    
    private var courseInfoTemplate : String {
        return config?.courseEnrollmentConfig.webviewConfig.courseInfoURLTemplate ?? ""
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
        
        //Setting webView accessibilityValue for testing
        webView.evaluateJavaScript("document.getElementsByClassName('course-card')[0].innerText",
                                   completionHandler: { (result: AnyObject?, error: NSError?) in
                                    
                                    if (error == nil) {
                                        self.webView.accessibilityValue = "findCoursesLoaded"
                                    }
        })
        thing.superview?.bringSubviewToFront(thing)
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

extension FindCoursesWebViewHelper: UISearchBarDelegate {
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let searchTerms = searchBar.text, searchURL = searchBaseURL else { return }
        if let URL = FindCoursesWebViewHelper.buildQuery(searchURL.URLString, toolbarString: searchTerms) {
            loadRequestWithURL(URL)
        }
    }

    @objc static func buildQuery(baseURL: String, toolbarString: String) -> NSURL? {
        let items = toolbarString.componentsSeparatedByString(" ")
        let escapedItems = items.flatMap { $0.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) }
        let searchTerm = "search_query=" + escapedItems.joinWithSeparator("+")
        let newQuery: String
        if baseURL.containsString("?") {
            newQuery = baseURL + "&" + searchTerm
        } else {
            newQuery = baseURL + "?" + searchTerm

        }
        return NSURL(string: newQuery)
    }
}
