//
//  SnackbarViewsTests.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

@testable import edX

class SnackbarViewsTests: SnapshotTestCase {
    func testVersionUpgradeView() {
        let upgradeView = VersionUpgradeView(message: Strings.VersionUpgrade.newVersionAvailable)
        
        let size = upgradeView.systemLayoutSizeFitting(screenSize)
        upgradeView.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        upgradeView.layoutIfNeeded()
        assertSnapshotValidWithContent(upgradeView)
    }
    
    func testOfflineView() {
        let offlineView = OfflineView(message: Strings.offline, selector: nil)
        
        let size = offlineView.systemLayoutSizeFitting(screenSize)
        offlineView.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        offlineView.layoutIfNeeded()
        assertSnapshotValidWithContent(offlineView)
    }
}
