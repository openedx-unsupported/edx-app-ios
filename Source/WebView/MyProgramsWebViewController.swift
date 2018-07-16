//
//  MyProgramsWebViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 7/13/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import WebKit

let myProgramsBaseURL = "https://courses.edx.org/dashboard"
let myProgramsPath = "/programs_fragment/?mobile_only=true"

class MyProgramsWebViewController: UIViewController {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXRouterProvider
    fileprivate let environment: Environment?
    private let webController: AuthenticatedWebViewController
    private let programDetailsURL: URL?
    
    init(environment: Environment, programDetailsURL: URL? = nil) {
        webController = AuthenticatedWebViewController(environment: environment)
        self.environment = environment
        self.programDetailsURL = programDetailsURL
        super.init(nibName: nil, bundle: nil)
        webController.webViewDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadPrograms()
    }

    // MARK:- Methods -
    func setupView() {
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
        view.addSubview(webController.view)
        webController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    func loadPrograms() {
        let urlToLoad: URL
        if let programDetailsURL = programDetailsURL {
            urlToLoad = programDetailsURL
        }
        else {
            guard let myProgramsURL  = URL(string: "\(myProgramsBaseURL)\(myProgramsPath)") else { return }
            urlToLoad = myProgramsURL
        }
        let request = NSURLRequest(url: urlToLoad)
        webController.loadRequest(request: request)
    }
    
}

extension MyProgramsWebViewController: WebViewDelegate {
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
        guard let url = request.url else { return true }
        let didNavigate = environment?.router?.navigate(to: url, from: self, bottomBar: nil) ?? false
        return !didNavigate
    }
    
    func webViewContainingController() -> UIViewController {
        return self
    }
}
