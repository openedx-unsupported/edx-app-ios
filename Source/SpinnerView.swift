//
//  SpinnerView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private var startTime : TimeInterval?

private let animationKey = "org.edx.spin"

public class SpinnerView : UIView {
    
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
    
    private let content = UIImageView()
    private let size : Size
    private var stopped : Bool = false {
        didSet {
            if hidesWhenStopped {
                self.isHidden = stopped
            }
        }
    }
    
    public var hidesWhenStopped = false
    
    public init(size : Size, color : Color) {
        self.size = size
        super.init(frame : CGRect.zero)
        addSubview(content)
        content.image = Icon.Spinner.imageWithFontSize(size: 30)
        content.tintColor = color.value
        content.contentMode = .scaleAspectFit
    }
    
    public override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        content.frame = self.bounds
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToWindow() {
        if !stopped {
            addSpinAnimation()
        }
        else {
            removeSpinAnimation()
        }
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
    
    private func addSpinAnimation() {
        if let window = self.window {
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
            let dots = 8
            let direction : Double = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? 1 : -1
            animation.keyTimes = Array(count: dots) {
                return (Double($0) / Double(dots)) as NSNumber
            }
            animation.values = Array(count: dots) {
                return (direction * Double($0) / Double(dots)) * 2.0 * .pi as NSNumber
            }
            animation.repeatCount = Float.infinity
            animation.duration = 0.6
            animation.isAdditive = true
            animation.calculationMode = kCAAnimationDiscrete
            /// Set time to zero so they all sync up
            animation.beginTime = window.layer.convertTime(0, to: self.layer)
            self.content.layer.add(animation, forKey: animationKey)
        }
        else {
            removeSpinAnimation()
        }
    }
    
    private func removeSpinAnimation() {
        self.content.layer.removeAnimation(forKey: animationKey)
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
