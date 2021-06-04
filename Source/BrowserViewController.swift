//
//  BrowserViewController.swift
//  edX
//
//  Created by Muhammad Umer on 04/06/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

class BrowserViewController: UIViewController {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & ReachabilityProvider
    
    private lazy var webController = AuthenticatedWebViewController(environment: environment)
    
    private let url: URL
    private let environment: Environment
    
    init(url: URL, environment: Environment) {
        self.url = url
        self.environment = environment
        super.init(nibName: nil, bundle :nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSubview()
        loadRequest()
    }
    
    private func loadRequest() {
        let request = NSURLRequest(url: url)
        webController.loadRequest(request: request)
    }
    
    private func configureSubview() {
        addSubviews()
        addCloseButton()
    }
    
    private func addSubviews() {
        addChild(webController)
        webController.didMove(toParent: self)
        view.addSubview(webController.view)
        
        webController.view.snp.remakeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: 20), style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = closeButton
        
        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
