//
//  OEXTextStyle+Swift.swift
//  edX
//
//  Created by Michael Katz on 5/17/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class OEXTextStyleWithShadow: OEXTextStyle {
    var shadow: ShadowStyle?

    override var attributes: [String : Any] {
        var attr = super.attributes
        if let shadowStyle = shadow {
            attr[NSShadowAttributeName] = shadowStyle.shadow
        }
        return attr as [String : AnyObject]
    }
    
}
