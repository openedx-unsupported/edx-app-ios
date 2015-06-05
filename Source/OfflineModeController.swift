//
//  OfflineModeController.swift
//  edX
//
//  Created by Akiva Leffert on 5/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


/// Convenient class for supporting an offline mode overlay above the top of a controller or its navigation bar
/// as appropriate
///
/// If you need to use this in the context of a scroll view, it's recommended to use `ContentInsetsController` instead
public class OfflineModeController: ViewTopMessageController {
    let reachability : Reachability
    
    public init(reachability : Reachability = InternetReachability(), styles : OEXStyles) {
        let messageView = OfflineModeView(frame : CGRectZero, styles : styles)
        self.reachability = reachability
        
        reachability.startNotifier()
        
        super.init(messageView : messageView, active : {
            return !reachability.isReachable()
        })
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: kReachabilityChangedNotification) { (notification, observer, _) in
            observer.updateAnimated()
        }
    }
}
