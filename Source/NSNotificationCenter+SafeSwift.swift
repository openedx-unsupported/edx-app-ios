//
//  NSNotificationCenter+SafeSwift.swift
//  edX
//
//  Created by Akiva Leffert on 5/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

extension NSNotificationCenter {
    func oex_addObserver<A : AnyObject>(observer : A, name : String, action : (NSNotification, A, OEXRemovable) -> Void) {
        oex_addObserver(observer, notification: name) { (notification, observer, removable) -> Void in
            action(notification, observer as! A, removable)
        }
    }
   
}
