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
        case small
        case medium
        case large
    }
    
    public enum Color {
        case primary
        case white
        
        fileprivate var value : UIColor {
            switch self {
            case .primary: return OEXStyles.shared().primaryBaseColor()
            case .white: return OEXStyles.shared().neutralWhite()
            }
        }
    }
    
    private var activityIndicator: MaterialActivityIndicatorView?
    
    private let size: Size
    private let color: Color
    
    public init(size: Size, color: Color) {
        self.size = size
        self.color = color
        
        super.init(frame : .zero)
        accessibilityIdentifier = "SpinnerView:view"
        activityIndicator?.accessibilityIdentifier = "SpinnerView:activity-indicator"
        activityIndicator = MaterialActivityIndicatorView()
        if let view = activityIndicator {
            addSubview(view)
        }
        activityIndicator?.startAnimating()
        addObservers()        
    }
    
    public override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        activityIndicator?.frame = bounds
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToSuperview() {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override var intrinsicContentSize: CGSize {
        switch size {
        case .small:
            return CGSize(width: 12, height: 12)
        case .medium:
            return CGSize(width: 18, height: 18)
        case .large:
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
    
    func startAnimating() {
        DispatchQueue.main.async { [weak self] in
            self?.animate()
        }
    }

    private func animate() {
            activityIndicator?.removeFromSuperview()
            activityIndicator = MaterialActivityIndicatorView()
            if let view = activityIndicator {
                addSubview(view)
            }
            activityIndicator?.color = color.value
            activityIndicator?.startAnimating()
        }
    
    func stopAnimating() {
        activityIndicator?.removeFromSuperview()
    }
}
