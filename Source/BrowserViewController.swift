//
//  BrowserViewController.swift
//  edX
//
//  Created by Muhammad Umer on 04/06/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

protocol BrowserViewControllerDelegate: AnyObject {
    func didDismissBrowser()
}

class BrowserViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & ReachabilityProvider & OEXStylesProvider & NetworkManagerProvider
    
    private lazy var webController = AuthenticatedWebViewController(environment: environment)
    
    private let url: URL
    private let environment: Environment
    weak var delegate: BrowserViewControllerDelegate?
    
    init(title: String? = nil, url: URL, environment: Environment, alwaysRequireAuth: Bool = false) {
        self.url = url
        self.environment = environment
        super.init(nibName: nil, bundle :nil)
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = environment.styles.standardBackgroundColor()
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
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "BrowserViewController:close-button"
        navigationItem.rightBarButtonItem = closeButton
        
        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true) {
                self?.delegate?.didDismissBrowser()
            }
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}
