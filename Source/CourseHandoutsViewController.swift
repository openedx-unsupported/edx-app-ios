//
//  CourseHandoutsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class CourseHandoutsViewControllerEnvironment : NSObject {
    let styles : OEXStyles
    let networkManager : NetworkManager?
    
    init(styles : OEXStyles, networkManager : NetworkManager) {
        self.styles = styles
        self.networkManager = networkManager
    }
}

public class CourseHandoutsViewController: UIViewController, UIWebViewDelegate {
    
    let environment : CourseHandoutsViewControllerEnvironment
    let handoutsURLString : String?
    let webView : UIWebView
    let loadController : LoadStateViewController
    let handouts : BackedStream<String> = BackedStream()
    
    init(environment : CourseHandoutsViewControllerEnvironment, handoutsURLString : String?) {
        self.environment = environment
        self.handoutsURLString = handoutsURLString
        self.webView = UIWebView()
        self.loadController = LoadStateViewController(styles: self.environment.styles)
        
        super.init(nibName: nil, bundle: nil)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        loadController.setupInController(self, contentView: webView)
        addSubviews()
        setConstraints()
        setStyles()
        webView.delegate = self
        loadHandouts()
    }
    
    func addSubviews() {
        view.addSubview(webView)
    }
    
    func setConstraints() {
        webView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }
    
    func setStyles() {
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        self.navigationItem.title = OEXLocalizedString("COURSE_HANDOUTS", nil)
    }

    func loadHandouts() {
        if let URLString = handoutsURLString {
            let request = CourseInfoAPI.getHandoutsFromURLString(URLString: URLString)
            if let loader = self.environment.networkManager?.streamForRequest(request, persistResponse: true).dropFailuresAfterSuccess() {
                handouts.backWithStream(loader)
            }
            addListener()
        }
        
    }
    
    func addListener() {
        handouts.listenOnce(self, fireIfAlreadyLoaded: true, success: { [weak self]courseHandouts in
            let displayHTML = self?.environment.styles.styleHTMLContent(courseHandouts)
            if let apiHostUrl = OEXConfig.sharedConfig().apiHostURL() {
                self?.webView.loadHTMLString(displayHTML, baseURL: NSURL(string: apiHostUrl))
            }
            
            self?.loadController.state = .Loaded
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error: error)
        } )
    }
    
    override public func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.bottomLayoutGuide.length, right: 0)
        super.updateViewConstraints()
    }
    
    //MARK: UIWebView delegate

    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (navigationType != UIWebViewNavigationType.Other) {
            if let URL = request.URL {
                 UIApplication.sharedApplication().openURL(URL)
                return false
            }
        }
        return true
    }
    
}
