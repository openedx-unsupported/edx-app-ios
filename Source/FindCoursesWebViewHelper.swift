//
//  FindCoursesWebViewHelper.swift
//  edX
//
//  Created by Akiva Leffert on 11/9/15.
//  Copyright © 2015-2016 edX. All rights reserved.
//

import UIKit
import WebKit

enum ParameterKeys {
    static let searchQuery = "search_query"
    static let subject = "subject"
}

@objc protocol FindCoursesWebViewHelperDelegate : class {
    func webViewHelper(helper : FindCoursesWebViewHelper, shouldLoadLinkWithRequest request: NSURLRequest) -> Bool
    func containingControllerForWebViewHelper(helper : FindCoursesWebViewHelper) -> UIViewController
}

class FindCoursesWebViewHelper: NSObject {
    
    typealias Environment = OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider & OEXAnalyticsProvider
    fileprivate let environment: Environment?
    weak var delegate : FindCoursesWebViewHelperDelegate?
    fileprivate let contentView = UIView()
    fileprivate let webView = WKWebView()
    fileprivate let searchBar = UISearchBar()
    fileprivate lazy var popularSubjectsController: PopularSubjectsViewController = {
        let controller = PopularSubjectsViewController()
        controller.collectionView.subjectsDelegate = self
        return controller
    }()
    fileprivate var loadController = LoadStateViewController()
    
    fileprivate var request : NSURLRequest? = nil
    var searchBaseURL: URL?
    fileprivate let searchQuery:String?
    let bottomBar: UIView?
    private var urlObservation: NSKeyValueObservation?
    private var subjectDiscoveryEnabled: Bool = false
    private var popularSubjectsHeight: CGFloat = 125
    
    init(environment: Environment?, delegate: FindCoursesWebViewHelperDelegate?, bottomBar: UIView?, showSearch: Bool, searchQuery: String?, showSubjects: Bool = false) {
        self.environment = environment
        self.delegate = delegate
        self.bottomBar = bottomBar
        self.searchQuery = searchQuery
        super.init()
        
        webView.navigationDelegate = self
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.accessibilityIdentifier = "find-courses-webview"

        if let container = delegate?.containingControllerForWebViewHelper(helper: self) {
            container.view.addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.edges.equalTo(container.safeEdges)
            }
            loadController.setupInController(controller: container, contentView: contentView)

            let searchBarEnabled = (environment?.config.courseEnrollmentConfig.webviewConfig.nativeSearchBarEnabled ?? false) && showSearch
            subjectDiscoveryEnabled = (environment?.config.courseEnrollmentConfig.webviewConfig.subjectDiscoveryEnabled ?? false) && environment?.session.currentUser != nil && showSubjects

            var topConstraintItem: ConstraintItem = contentView.snp.top
            var webViewBottom: ConstraintItem = contentView.snp.bottom
            if searchBarEnabled {
                searchBar.delegate = self
                contentView.addSubview(searchBar)

                searchBar.snp.makeConstraints{ make in
                    make.leading.equalTo(contentView)
                    make.trailing.equalTo(contentView)
                    make.top.equalTo(contentView)
                }
                topConstraintItem = searchBar.snp.bottom
            }
            
            if subjectDiscoveryEnabled {
                container.addChildViewController(popularSubjectsController)
                contentView.addSubview(popularSubjectsController.view)
                popularSubjectsController.didMove(toParentViewController: container)
                
                // Add observation.
                urlObservation = webView.observe(\.url, changeHandler: { [weak self] (webView, change) in
                    self?.showOrHideSubjects()
                })
                
                popularSubjectsController.view.snp.makeConstraints { make in
                    make.leading.equalTo(contentView).offset(StandardVerticalMargin)
                    make.trailing.equalTo(contentView)
                    make.top.equalTo(topConstraintItem)
                    make.height.equalTo(popularSubjectsHeight)
                }
                
                topConstraintItem = popularSubjectsController.view.snp.bottom
            }
            
            contentView.addSubview(webView)
            if let bar = bottomBar {
                contentView.addSubview(bar)
                bar.snp.makeConstraints { make in
                    make.leading.equalTo(contentView)
                    make.trailing.equalTo(contentView)
                    make.bottom.equalTo(contentView)
                }
                webViewBottom = bar.snp.top
            }
            
            webView.snp.makeConstraints { make in
                make.leading.equalTo(contentView)
                make.trailing.equalTo(contentView)
                make.bottom.equalTo(webViewBottom)
                make.top.equalTo(topConstraintItem)
            }
            addObserver()
        }
    }
    
    private func addObserver() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.UIDeviceOrientationDidChange.rawValue) { [weak self] (_, _, _) in
            self?.showOrHideSubjects()
        }
    }
    
    private func showOrHideSubjects() {
        let hideSubjectsView = isIphoneAndVerticallyCompact || isQueried
        let height: CGFloat = hideSubjectsView ? 0 : popularSubjectsHeight
        popularSubjectsController.view.snp.updateConstraints() { make in
            make.height.equalTo(height)
        }
        popularSubjectsController.view.isHidden = hideSubjectsView
    }
    
    private var isIphoneAndVerticallyCompact: Bool {
        guard let container = delegate?.containingControllerForWebViewHelper(helper: self) else { return false }
        return container.isVerticallyCompact() && UIDevice.current.userInterfaceIdiom == .phone
    }
    
    private var isQueried: Bool {
        guard let url = webView.url?.absoluteString else { return false }
        return url.contains(find: "\(ParameterKeys.subject)=")
    }

    private var courseInfoTemplate : String {
        return environment?.config.courseEnrollmentConfig.webviewConfig.courseInfoURLTemplate ?? ""
    }
    
    var isWebViewLoaded : Bool {
        return self.loadController.state.isLoaded
    }

    public func load(withURL url: URL) {
        var discoveryURL = url
        
        if let searchURL = searchBaseURL, let searchQuery = searchQuery, var params = (url as NSURL).oex_queryParameters() as? [String : String] {
            params[ParameterKeys.searchQuery] = searchQuery.addingPercentEncodingForRFC3986
            if let urlWithQuery = FindCoursesWebViewHelper.buildQuery(baseURL: searchURL.URLString, params: params) {
                discoveryURL = urlWithQuery
            }
        }

        loadRequest(withURL: discoveryURL)
    }

    fileprivate func loadRequest(withURL url: URL) {
        let request = NSURLRequest(url: url)
        webView.load(request as URLRequest)
        self.request = request
    }

    fileprivate func showError(error : NSError) {
        let buttonInfo = MessageButtonInfo(title: Strings.reload) {[weak self] _ in
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

extension FindCoursesWebViewHelper: WKNavigationDelegate {
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
        if let credential = environment?.config.URLCredentialForHost(challenge.protectionSpace.host as NSString) {
            completionHandler(.useCredential, credential)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension FindCoursesWebViewHelper: SubjectsCollectionViewDelegate {
    func subjectsCollectionView(_ collectionView: SubjectsCollectionView, didSelect subject: Subject) {
        guard let url = webView.url as NSURL?,
            let searchURL = searchBaseURL,
            var params: [String: String] = url.oex_queryParameters() as? [String : String] else { return }
        params[ParameterKeys.subject] = subject.filter.addingPercentEncodingForRFC3986
        environment?.analytics.trackSubjectDiscovery(subjectID: subject.filter)
        if let newURL = FindCoursesWebViewHelper.buildQuery(baseURL: searchURL.URLString, params: params) {
            loadRequest(withURL: newURL)
        }
    }
    
    func subjectsCollectionView(_ collectionView: SubjectsCollectionView, showAllSubjects: Bool) {
        guard let container = delegate?.containingControllerForWebViewHelper(helper: self) else {
            return
        }
        environment?.analytics.trackSubjectDiscovery(subjectID: "View All Subjects")
        environment?.router?.showAllSubjects(from: container, subjectDelegate: self)
    }
}

extension FindCoursesWebViewHelper: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let url = webView.url as NSURL?,
            let searchText = searchBar.text,
            let searchURL = searchBaseURL,
            var params: [String: String] = url.oex_queryParameters() as? [String : String]
            else {
                return
        }
        
        params[ParameterKeys.searchQuery] = searchText.addingPercentEncodingForRFC3986
        if let URL = FindCoursesWebViewHelper.buildQuery(baseURL: searchURL.URLString, params: params) {
            loadRequest(withURL: URL)
        }
    }
    
    static func buildQuery(baseURL: String, params: [String: String]) -> URL? {
        var query = baseURL
        for param in params {
            let join = query.contains("?") ? "&" : "?"
            query = query + join + param.key + "=" + param.value
        }
        
        return URL(string: query)
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
