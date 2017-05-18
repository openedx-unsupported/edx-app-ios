//
//  OEXStyles+Profile.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

/** Profile Views-specific styles */
extension OEXStyles {
    
    public func profileImageBorderColor() -> UIColor {
        return neutralWhite()
    }
    
    func profileImageViewBorder(width: CGFloat = 1.0) -> BorderStyle {
        return BorderStyle(cornerRadius: .Circle, width: .Size(width), color: OEXStyles.shared().profileImageBorderColor())
    }
    
}
