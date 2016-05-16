//
//  WarningInfoViewTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class WarningInfoViewTests: SnapshotTestCase {

    func testOfflineView() {
        
        let rootController = UIApplication.sharedApplication().keyWindow?.rootViewController
        
        let offlineView = WarningInfoView(frame : CGRectZero, warningType: .OfflineMode, viewController: rootController)
        
        let size = offlineView.systemLayoutSizeFittingSize(self.screenSize)
        offlineView.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        offlineView.layoutIfNeeded()
        assertSnapshotValidWithContent(offlineView)
        
        
        let versionUpgradeView = WarningInfoView(frame : CGRectZero, warningType: .VersionUpgrade, viewController: rootController)
        
        versionUpgradeView.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        versionUpgradeView.layoutIfNeeded()
        assertSnapshotValidWithContent(versionUpgradeView)
    }

}
