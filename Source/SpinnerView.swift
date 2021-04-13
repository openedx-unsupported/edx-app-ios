//
//  SpinnerView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class SpinnerView: UIView {
    
    public enum Size {
        case Small
        case Medium
        case Large
    }
    
    public enum Color {
        case Primary
        case White
        
        fileprivate var value : UIColor {
            switch self {
            case .Primary: return OEXStyles.shared().primaryBaseColor()
            case .White: return OEXStyles.shared().neutralWhite()
            }
        }
    }
    
    private let activityIndicator = MaterialActivityIndicatorView()
    private let size: Size
    private var stopped: Bool = false {
        didSet {
            if hidesWhenStopped {
                isHidden = stopped
            }
        }
    }
    
    public var hidesWhenStopped = false
    
    public init(size: Size, color: Color) {
        self.size = size
        super.init(frame : .zero)
        accessibilityIdentifier = "SpinnerView:view"
        activityIndicator.accessibilityIdentifier = "SpinnerView:activity-indicator"
        addSubview(activityIndicator)
        activityIndicator.color = color.value
        addObservers()
    }
    
    public override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        activityIndicator.frame = bounds
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToWindow() {
        if !stopped {
            addSpinAnimation()
        } else {
            removeSpinAnimation()
        }
    }
    
    public override func didMoveToSuperview() {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override var intrinsicContentSize: CGSize {
        switch size {
        case .Small:
            return CGSize(width: 12, height: 12)
        case .Medium:
            return CGSize(width: 18, height: 18)
        case .Large:
            return CGSize(width: 24, height: 24)
        }
    }
    
    private func addObservers() {
        NotificationCenter.default.oex_addObserver(observer: self, name: UIApplication.willEnterForegroundNotification.rawValue) { (_, observer ,_) in
            observer.startAnimating()
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: UIApplication.didEnterBackgroundNotification.rawValue) { (_, observer, _) in
            observer.stopAnimating()
        }
    }
    
    private func addSpinAnimation() {
        if window != nil {
            activityIndicator.startAnimating()
        }
        else {
            removeSpinAnimation()
        }
    }
    
    private func removeSpinAnimation() {
        activityIndicator.stopAnimating()
    }
    
    public func startAnimating() {
        if stopped {
            addSpinAnimation()
        }
        stopped = false
    }
    
    public func stopAnimating() {
        removeSpinAnimation()
        stopped = true
    }
}
