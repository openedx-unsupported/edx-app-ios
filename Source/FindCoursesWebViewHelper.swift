//
//  FindCoursesWebViewHelper.swift
//  edX
//
//  Created by Akiva Leffert on 11/9/15.
//  Copyright © 2015-2016 edX. All rights reserved.
//

import UIKit
import WebKit

fileprivate enum QueryParameterKeys {
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
    weak var delegate: FindCoursesWebViewHelperDelegate?
    fileprivate let contentView = UIView()
    fileprivate let webView = WKWebView()
    fileprivate let searchBar = UISearchBar()
    fileprivate lazy var subjectsController: PopularSubjectsViewController = {
        let controller = PopularSubjectsViewController()
        controller.delegate = self
        return controller
    }()
    fileprivate var loadController = LoadStateViewController()
    
    fileprivate var request: URLRequest? = nil
    var searchBaseURL: URL?
    fileprivate let searchQuery:String?
    let bottomBar: UIView?
    private let searchBarEnabled: Bool
    private let showSubjects: Bool
    private var urlObservation: NSKeyValueObservation?
    private var subjectDiscoveryEnabled: Bool = false
    private var subjectsViewHeight: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 145 : 125
    }
    fileprivate var params: [String: String]? {
        return (webView.url as NSURL?)?.oex_queryParameters() as? [String : String]
    }
    
    init(environment: Environment?, delegate: FindCoursesWebViewHelperDelegate?, bottomBar: UIView?, showSearch: Bool, searchQuery: String?, showSubjects: Bool = false) {
        self.environment = environment
        self.delegate = delegate
        self.bottomBar = bottomBar
        self.searchQuery = searchQuery
        self.showSubjects = showSubjects
        searchBarEnabled = (environment?.config.courseEnrollmentConfig.webviewConfig.nativeSearchBarEnabled ?? false) && showSearch
        super.init()
        webView.navigationDelegate = self
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.accessibilityIdentifier = "find-courses-webview"
        
        guard let container = delegate?.containingControllerForWebViewHelper(helper: self) else { return }
        container.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(container.safeEdges)
        }
        loadController.setupInController(controller: container, contentView: contentView)
        refreshView()
    }
    
    @objc func refreshView() {
        guard let container = delegate?.containingControllerForWebViewHelper(helper: self) else { return }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let isUserLoggedIn = environment?.session.currentUser != nil

        subjectDiscoveryEnabled = (environment?.config.courseEnrollmentConfig.webviewConfig.subjectDiscoveryEnabled ?? false) && isUserLoggedIn && showSubjects

        var topConstraintItem: ConstraintItem = contentView.snp.top
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
            container.addChildViewController(subjectsController)
            contentView.addSubview(subjectsController.view)
            subjectsController.didMove(toParentViewController: container)
            subjectsController.view.snp.makeConstraints { make in
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView)
                make.top.equalTo(topConstraintItem)
                make.height.equalTo(subjectsViewHeight)
            }

            topConstraintItem = subjectsController.view.snp.bottom
        }

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
            make.top.equalTo(topConstraintItem)
        }

        addObserver()
    }
    
    private func addObserver() {
        if subjectDiscoveryEnabled {
            // Add observation.
            urlObservation = webView.observe(\.url, changeHandler: { [weak self] (webView, change) in
                self?.updateSubjectsVisibility()
            })
        }
    }
    
    @objc func updateSubjectsVisibility() {
        if contentView.subviews.contains(subjectsController.view) {
            let hideSubjectsView = isiPhoneAndVerticallyCompact || isWebViewQueriedSubject
            let height: CGFloat = hideSubjectsView ? 0 : subjectsViewHeight
            subjectsController.view.snp.remakeConstraints { make in
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView)
                make.top.equalTo(searchBarEnabled ? searchBar.snp.bottom : contentView)
                make.height.equalTo(height)
            }
            subjectsController.view.isHidden = hideSubjectsView
        }
    }
    
    private var isiPhoneAndVerticallyCompact: Bool {
        guard let container = delegate?.containingControllerForWebViewHelper(helper: self) else { return false }
        return container.isVerticallyCompact() && UIDevice.current.userInterfaceIdiom == .phone
    }
    
    private var isWebViewQueriedSubject: Bool {
        guard let url = webView.url?.absoluteString else { return false }
        return url.contains(find: "\(QueryParameterKeys.subject)=")
    }

    private var courseInfoTemplate : String {
        return environment?.config.courseEnrollmentConfig.webviewConfig.courseInfoURLTemplate ?? ""
    }
    
    var isWebViewLoaded : Bool {
        return self.loadController.state.isLoaded
    }

    public func load(withURL url: URL) {
        var discoveryURL = url
        
        if let searchURL = searchBaseURL, let searchQuery = searchQuery, var params = params {
            set(value: searchQuery, for: QueryParameterKeys.searchQuery, in: &params)
            if let url = FindCoursesWebViewHelper.buildQuery(baseURL: searchURL.URLString, params: params) {
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

extension FindCoursesWebViewHelper: SubjectsViewControllerDelegate, PopularSubjectsViewControllerDelegate {
    
    private func filterCourses(with subject: Subject) {
        guard let searchURL = searchBaseURL,
            var params = params else { return }
        set(value: subject.filter, for: QueryParameterKeys.subject, in: &params)
        environment?.analytics.trackSubjectDiscovery(subjectID: subject.filter)
        if let url = FindCoursesWebViewHelper.buildQuery(baseURL: searchURL.URLString, params: params) {
            loadRequest(withURL: url)
        }
    }
    
    private func viewAllSubjects() {
        guard let container = delegate?.containingControllerForWebViewHelper(helper: self) else { return }
        environment?.analytics.trackSubjectDiscovery(subjectID: "View All Subjects")
        environment?.router?.showAllSubjects(from: container, delegate: self)
    }
    
    func popularSubjectsViewController(_ controller: PopularSubjectsViewController, didSelect subject: Subject) {
        filterCourses(with: subject)
    }
    
    func didSelectViewAllSubjects(_ controller: PopularSubjectsViewController) {
        viewAllSubjects()
    }
    
    func subjectsViewController(_ controller: SubjectsViewController, didSelect subject: Subject) {
        filterCourses(with: subject)
    }
    
}

extension FindCoursesWebViewHelper: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        guard let searchText = searchBar.text,
            let searchURL = searchBaseURL,
            var params = params else { return }
        set(value: searchText, for: QueryParameterKeys.searchQuery, in: &params)
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
