//
//  VersionUpgradeController.swift
//  edX
//
//  Created by Saeed Bashir on 5/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

/// Convenient class for supporting an offline mode overlay above the top of a controller or its navigation bar
/// as appropriate
///
/// If you need to use this in the context of a scroll view, it's recommended to use `ContentInsetsController` instead
public class VersionUpgradeController: ViewTopMessageController {
    
    public init(viewController: UIViewController?) {
        let messageView = WarningInfoView(frame : CGRectZero, warningType: .VersionUpgrade, viewController: viewController)
        
        super.init(messageView : messageView, active : {
            return VersionUpgradeInfoController.sharedController.isNewVersionAvailable
        })
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: AppNewVersionAvailableNotification) { (notification, observer, _) in
            observer.updateAnimated()
        }
    }
}