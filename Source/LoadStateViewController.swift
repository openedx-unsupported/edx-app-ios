//
//  LoadStateViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

import edXCore

public enum LoadState {
    case Initial
    case Loaded
    case Empty(icon : Icon?, message : String?, attributedMessage : NSAttributedString?, accessibilityMessage : String?, buttonInfo : MessageButtonInfo?)
    // if attributed message is set then message is ignored
    // if message is set then the error is ignored
    case Failed(error : NSError?, icon : Icon?, message : String?, attributedMessage : NSAttributedString?, accessibilityMessage : String?, buttonInfo : MessageButtonInfo?)
    
    var accessibilityMessage : String? {
        switch self {
        case .Initial: return nil
        case .Loaded: return nil
        case let .Empty(info): return info.accessibilityMessage
        case let .Failed(info): return info.accessibilityMessage
        }
    }
    
    var isInitial : Bool {
        switch self {
        case .Initial: return true
        default: return false
        }
    }
    
    var isLoaded : Bool {
        switch self {
        case .Loaded: return true
        default: return false
        }
    }
    
    var isError : Bool {
        switch self {
        case .Failed(_): return true
        default: return false
        }
    }
    
    static func failed(error : NSError? = nil, icon : Icon? = .UnknownError, message : String? = nil, attributedMessage : NSAttributedString? = nil, accessibilityMessage : String? = nil, buttonInfo : MessageButtonInfo? = nil) -> LoadState {
        return LoadState.Failed(error : error, icon : icon, message : message, attributedMessage : attributedMessage, accessibilityMessage : accessibilityMessage, buttonInfo : buttonInfo)
    }
    
    static func empty(icon : Icon?, message : String? = nil, attributedMessage : NSAttributedString? = nil, accessibilityMessage : String? = nil, buttonInfo : MessageButtonInfo? = nil) -> LoadState {
        return LoadState.Empty(icon: icon, message: message, attributedMessage: attributedMessage, accessibilityMessage : accessibilityMessage, buttonInfo : buttonInfo)
    }
}

/// A controller should implement this protocol to support reloading with fullscreen errors for unknownErrors
@objc protocol LoadStateViewReloadSupport {
    func loadStateViewReload()
}

class LoadStateViewController : UIViewController {
    
    private let loadingView : UIView
    private var contentView : UIView?
    private let messageView : IconMessageView
    private var delegate: LoadStateViewReloadSupport?
    private var madeInitialAppearance : Bool = false
    
    var state : LoadState = .Initial {
        didSet {
            // this sets a background color so when the view is pushed in it doesn't have a black or weird background
            switch state {
            case .Initial:
                view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
            default:
                view.backgroundColor = UIColor.clear
            }
            updateAppearanceAnimated(animated: madeInitialAppearance)
        }
    }
    
    var insets : UIEdgeInsets = .zero {
        didSet {
            view.setNeedsUpdateConstraints()
        }
    }
    
    init() {
        messageView = IconMessageView()
        loadingView = SpinnerView(size: .Large, color: .Primary)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var messageStyle : OEXTextStyle {
        return messageView.messageStyle
    }
    
    override func loadView() {
        view = PassthroughView()
    }
    
    func setupInController(controller : UIViewController, contentView : UIView) {
        controller.addChildViewController(self)
        didMove(toParentViewController: controller)
        
        self.contentView = contentView
        contentView.alpha = 0
        
        controller.view.addSubview(loadingView)
        controller.view.addSubview(messageView)
        controller.view.addSubview(view)
        
        if isSupportingReload() {
            delegate = controller as? LoadStateViewReloadSupport
        }
    }
    
    func loadStateViewReload() {
        if isSupportingReload() {
            delegate?.loadStateViewReload()
        }
    }
    
    func isSupportingReload() -> Bool {
        if let _ = parent as? LoadStateViewReloadSupport as? UIViewController {
            return true
        }
        
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageView.alpha = 0
        view.addSubview(messageView)
        view.addSubview(loadingView)
        
        state = .Initial
        
        view.setNeedsUpdateConstraints()
        view.isUserInteractionEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        madeInitialAppearance = true
    }
    
    override func updateViewConstraints() {
        loadingView.snp.remakeConstraints { make in
            make.center.equalTo(view)
        }
        
        messageView.snp.remakeConstraints { make in
            make.center.equalTo(view)
        }
        
        view.snp.remakeConstraints { make in
            if let superview = view.superview {
                make.edges.equalTo(superview).inset(insets)
            }
        }
        super.updateViewConstraints()
    }
    
    private func showOfflineSnackBarIfNecessary() {
        DispatchQueue.main.async { [weak self] in
            if let parent = self?.parent as? OfflineSupportViewController {
                parent.showOfflineSnackBarIfNecessary()
            }
        }
    }
    
    private func updateAppearanceAnimated(animated : Bool) {
        var alphas : (loading : CGFloat, message : CGFloat, content : CGFloat, touchable : Bool) = (loading : 0, message : 0, content : 0, touchable : false)
        
        UIView.animate(withDuration: 0.3 * TimeInterval()) { [weak self] in
            guard let owner = self else { return }
            switch owner.state {
            case .Initial:
                alphas = (loading : 1, message : 0, content : 0, touchable : false)
            case .Loaded:
                alphas = (loading : 0, message : 0, content : 1, touchable : false)
                owner.showOfflineSnackBarIfNecessary()
            case let .Empty(info):
                owner.messageView.buttonInfo = info.buttonInfo
                UIView.performWithoutAnimation {
                    if let message = info.attributedMessage {
                        owner.messageView.attributedMessage = message
                    }
                    else {
                        owner.messageView.message = info.message
                    }
                    owner.messageView.icon = info.icon
                }
                alphas = (loading : 0, message : 1, content : 0, touchable : true)
            case let .Failed(info):
                owner.messageView.buttonInfo = info.buttonInfo
                UIView.performWithoutAnimation {
                    if let error = info.error, error.oex_isNoInternetConnectionError {
                        owner.messageView.showError(message: Strings.networkNotAvailableMessageTrouble, icon: .InternetError)
                    }
                    else if let error = info.error as? OEXAttributedErrorMessageCarrying {
                        owner.messageView.showError(message: error.attributedDescription(withBaseStyle: owner.messageStyle), icon: info.icon)
                    }
                    else if let message = info.attributedMessage {
                        owner.messageView.showError(message: message, icon: info.icon)
                    }
                    else if let message = info.message {
                        owner.messageView.showError(message: message, icon: info.icon)
                    }
                    else if let error = info.error, error.errorIsThisType(NSError.oex_unknownNetworkError()) {
                        owner.messageView.showError(message: Strings.unknownError, icon: info.icon)
                    }
                    else if let error = info.error, error.errorIsThisType(NSError.oex_outdatedVersionError()) {
                        owner.messageView.setupForOutdatedVersionError()
                    }
                    else {
                        owner.messageView.showError(message: info.error?.localizedDescription, icon: info.icon)
                    }
                }
                alphas = (loading : 0, message : 1, content : 0, touchable : true)
                
                DispatchQueue.main.async {
                    owner.parent?.hideSnackBar()
                }
            }
            
            owner.messageView.accessibilityMessage = self?.state.accessibilityMessage
            owner.loadingView.alpha = alphas.loading
            owner.messageView.alpha = alphas.message
            owner.contentView?.alpha = alphas.content
            owner.view.isUserInteractionEnabled = alphas.touchable
        }
    }
    
}
