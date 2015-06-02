//
//  AuthenticatedWebViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

// Allows access to course content that requires authentication.
// Forwarding our oauth token to the server so we can get a web based cookie
public class AuthenticatedWebViewController: UIViewController, UIWebViewDelegate {
    
    private enum State {
        case CreatingSession
        case LoadingContent
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
    private var webView : UIWebView?
    private let loadController : LoadStateViewController
    
    private var state = State.CreatingSession
    
    private var contentRequest : NSURLRequest? = nil
    
    public init(environment : Environment) {
        self.environment = environment
        
        loadController = LoadStateViewController(styles: self.environment.styles)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        webView = {
            let webView = UIWebView(frame: self.view.bounds)
            webView.delegate = self
            self.view.addSubview(webView)
            webView.snp_makeConstraints({ (make) -> Void in
                make.edges.equalTo(self.view)
            })
            self.loadController.setupInController(self, contentView: webView)
            return webView
        }()
        
        if let request = self.contentRequest {
            loadRequest(request)
        }
    }
    
    var apiHostURL : String {
        return environment.config?.apiHostURL() ?? ""
    }
    
    public func loadRequest(request : NSURLRequest) {
        contentRequest = request
        loadController.state = .Initial
        state = .CreatingSession
        
        // First make sure we have a valid session token.
        // We don't really want to do this on every screen - but it's tricky not to, because
        // UIWebView doesn't send back HTTP status codes, so we can't tell if we're getting a 401 or 403
        // and get a new token. When we drop iOS7 support we should switch to WKWebView which will let us
        // actually examine the status code. See https://openedx.atlassian.net/browse/MA-790
        NSURL(string:apiHostURL + "/oauth2/login/").map { URL -> Void in
            let exchangeRequest = NSMutableURLRequest(URL: URL)
            exchangeRequest.HTTPMethod = HTTPMethod.POST.rawValue
            
            for (key, value) in self.environment.session?.authorizationHeaders ?? [:] {
                exchangeRequest.addValue(value, forHTTPHeaderField: key)
            }
            self.webView?.loadRequest(exchangeRequest)
        }
    }
    
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
                self.webView?.loadRequest(request)
            }
            else {
                loadController.state = LoadState.failed()
            }
        case .LoadingContent:
            loadController.state = .Loaded
        }
    }
    
    public func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        showError(error)
    }
    
    public func showError(error : NSError?, icon : Icon? = nil, message : String? = nil) {
        loadController.state = LoadState.failed(error : error, icon : icon, message : message)
    }

}

