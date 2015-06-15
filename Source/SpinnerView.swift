//
//  SpinnerView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class SpinnerView : UIView {
    
    public enum Size {
        case Small
        case Large
    }
    
    public enum Color {
        case Primary
        case White
        
        private var value : UIColor {
            switch self {
            case Primary: return OEXStyles.sharedStyles().primaryBaseColor()
            case White: return OEXStyles.sharedStyles().neutralWhite()
            }
        }
    }
    
    private let content = UILabel()
    private let size : Size
    
    init(size : Size, color : Color) {
        self.size = size
        super.init(frame : CGRectZero)
        addSubview(content)
        content.text = Icon.Spinner.textRepresentation
        content.font = Icon.fontWithSize(30)
        content.adjustsFontSizeToFitWidth = true
        content.baselineAdjustment = .AlignCenters
        content.minimumScaleFactor = 0.2
        
        content.textColor = color.value
    }
    
    public override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        content.frame = self.bounds
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToSuperview() {
        if self.superview != nil {
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
            let dots = 8
            animation.keyTimes = Array(count: dots) {
                return (Double($0) / Double(dots)) as NSNumber
            }
            animation.values = Array(count: dots) {
                return (Double($0) / Double(dots)) * 2.0 * M_PI as NSNumber
            }
            animation.repeatCount = Float.infinity
            animation.duration = 0.6
            animation.calculationMode = kCAAnimationDiscrete
            self.content.layer.addAnimation(animation, forKey: "spin")
        }
    }
    
    public override func intrinsicContentSize() -> CGSize {
        switch size {
        case .Small:
            return CGSizeMake(12, 12)
        case .Large:
            return CGSizeMake(24, 24)
        }
    }
}
