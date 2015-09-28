//
//  ProfileImageView.swift
//  edX
//
//  Created by Michael Katz on 9/17/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

@IBDesignable
class ProfileImageView: UIImageView {

    private func setup() {
        let borderStyle = OEXStyles.sharedStyles().profileImageViewBorder
        applyBorderStyle(borderStyle)
        backgroundColor = OEXStyles.sharedStyles().profileImageBorderColor()
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
