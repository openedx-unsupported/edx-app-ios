//
//  CircleImageView.swift
//  edX
//
//  Created by Michael Katz on 9/17/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

@IBDesignable
class CircleImageView: UIImageView {

    private func setup() {
        layer.borderWidth = 1
        layer.borderColor = OEXStyles.sharedStyles().profileImageBorderColor().CGColor
        layer.allowsEdgeAntialiasing = true
        layer.cornerRadius = frame.height/2
        
        clipsToBounds = true
        backgroundColor = UIColor.whiteColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
        let bundle = NSBundle(forClass: self.dynamicType)
        image = UIImage(named: "avatarPlaceholder", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
    }
    
}
