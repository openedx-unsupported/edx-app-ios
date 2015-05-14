//
//  LoadStateViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation


enum LoadState {
    case Initial
    case Loaded
    case Empty(icon : Icon, message : String)
    case Failed(error : NSError?, icon : Icon?, message : String?)
}

class LoadStateViewController : UIViewController, OEXStatusMessageControlling {
    private var _state : LoadState = .Initial
    
    private let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    private var contentView : UIView?
    private let messageView : IconMessageView
    
    init(styles : OEXStyles?) {
        messageView = IconMessageView(styles: styles)
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupInView(view : UIView, contentView : UIView) {
        self.contentView = contentView
        contentView.alpha = 0
        self.view.addSubview(loadingView)
        self.view.addSubview(messageView)
        view.addSubview(self.view)
    }
    
    var state : LoadState {
        get {
            return _state
        }
        set {
            setState(newValue, animated: false)
        }
    }
    
    var insets : UIEdgeInsets = UIEdgeInsetsZero {
        didSet {
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageView.alpha = 0
        view.addSubview(messageView)
        
        loadingView.startAnimating()
        view.addSubview(loadingView)
        
        setState(.Initial, animated: false)
        
        self.view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        loadingView.snp_updateConstraints {make in
            make.center.equalTo(view)
        }
        
        messageView.snp_updateConstraints {make in
            make.center.equalTo(view)
        }
        
        view.snp_updateConstraints { make in
            if let superview = view.superview {
                make.edges.equalTo(superview).insets(insets)
            }
        }
        super.updateViewConstraints()
    }
    
    func setState(state : LoadState, animated : Bool) {
        _state = state
        var alphas : (loading : CGFloat, message : CGFloat, content : CGFloat) = (loading : 0, message : 0, content : 0)
        
        UIView.animateWithDuration(0.3 * NSTimeInterval(animated)) {
            switch state {
            case .Initial:
                alphas = (loading : 1, message : 0, content : 0)
            case .Loaded:
                alphas = (loading : 0, message : 0, content : 1)
            case let .Empty(info):
                UIView.performWithoutAnimation {
                    self.messageView.message = info.message
                    self.messageView.icon = info.icon
                }
                alphas = (loading : 0, message : 1, content : 0)
            case let .Failed(info):
                UIView.performWithoutAnimation {
                    if let error = info.error where error.oex_isNoInternetConnectionError() {
                        self.messageView.showNoConnectionError()
                    }
                    else {
                        self.messageView.message = info.message ?? info.error?.localizedDescription
                        self.messageView.icon = info.icon ?? .UnknownError
                    }
                }
                alphas = (loading : 0, message : 1, content : 0)
            }
            
            self.loadingView.alpha = alphas.loading
            self.messageView.alpha = alphas.message
            self.contentView?.alpha = alphas.content
        }
    }
    
    func overlayViewsForStatusController(controller: OEXStatusMessageViewController!) -> [AnyObject]! {
        return []
    }
    
    func verticalOffsetForStatusController(controller: OEXStatusMessageViewController!) -> CGFloat {
        return 0
    }
    
    func showOverlayError(message : String) {
        OEXStatusMessageViewController.sharedInstance().showMessage(message, onViewController: self)
    }
    
}