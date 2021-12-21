//
//  SpinnerView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class SpinnerView: UIView {

        public enum Color {
            case primary
            case white

            fileprivate var value : UIColor {
                switch self {
                case .primary: return OEXStyles.shared().neutralBlack()
                case .white: return OEXStyles.shared().neutralWhite()
                }
            }
        }
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.accessibilityIdentifier = "SpinnerView:activity-indicator"
        indicator.hidesWhenStopped = true
        indicator.color = color.value

        return indicator
    }()

    private let color: Color
    
    public init(color: Color = .primary) {
        self.color = color
        
        super.init(frame : .zero)
        accessibilityIdentifier = "SpinnerView:view"

        addSubview(activityIndicator)
        activityIndicator.startAnimating()
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
    
    public override func didMoveToSuperview() {
        NotificationCenter.default.removeObserver(self)
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

        if !subviews.contains(activityIndicator) {
            addSubview(activityIndicator)
        }

        activityIndicator.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicator.removeFromSuperview()
    }
}
