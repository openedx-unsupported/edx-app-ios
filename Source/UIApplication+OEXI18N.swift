//
//  UIApplication+OEXI18N.swift
//  edX
//
//  Created by Michael Katz on 8/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit


extension UIApplication {
    class func isRTL() -> Bool {
        return sharedApplication().userInterfaceLayoutDirection == .RightToLeft
    }
}