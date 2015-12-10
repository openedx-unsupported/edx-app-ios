//
//  OfflineModeViewTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class OfflineModeViewTests: SnapshotTestCase {

    func testOfflineView() {
        let offlineView = OfflineModeView(frame : CGRectZero)
        
        let size = offlineView.systemLayoutSizeFittingSize(self.screenSize)
        offlineView.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        offlineView.layoutIfNeeded()
        assertSnapshotValidWithContent(offlineView)
    }

}
