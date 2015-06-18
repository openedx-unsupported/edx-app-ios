//
//  DownloadProgressViewTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import Foundation

class CourseOutlineHeaderViewTests : SnapshotTestCase {

    func testProgressView() {
        let progressView = CourseOutlineHeaderView(frame : CGRectZero, styles : OEXStyles(), shouldShowSpinner : true)
        
        let size = progressView.systemLayoutSizeFittingSize(self.screenSize)
        progressView.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        progressView.layoutIfNeeded()
        assertSnapshotValidWithContent(progressView)
    }
    
    override func setUp() {
        super.setUp()
        recordMode = true
    }
}