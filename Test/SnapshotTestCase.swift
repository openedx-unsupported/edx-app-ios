//
//  SnapshotTestCase
//  edX
//
//  Created by Akiva Leffert on 5/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let StandardTolerance : CGFloat = 0.005

protocol SnapshotTestable {
    func snapshotTestWithCase(_ testCase : FBSnapshotTestCase, referenceImagesDirectory: String, identifier: String) throws
    
    var snapshotSize : CGSize { get }
}

extension UIView : SnapshotTestable {
    func snapshotTestWithCase(_ testCase : FBSnapshotTestCase, referenceImagesDirectory: String, identifier: String) throws {
        try testCase.compareSnapshot(of: self, referenceImagesDirectory: referenceImagesDirectory, identifier: identifier, tolerance : StandardTolerance)
    }
    
    var snapshotSize : CGSize {
        return bounds.size
    }
}

extension CALayer : SnapshotTestable {
    func snapshotTestWithCase(_ testCase : FBSnapshotTestCase, referenceImagesDirectory: String, identifier: String) throws  {
        try testCase.compareSnapshot(of: self, referenceImagesDirectory: referenceImagesDirectory, identifier: identifier, tolerance : StandardTolerance)
    }
    
    var snapshotSize : CGSize {
        return bounds.size
    }
}

extension UIViewController : SnapshotTestable {
    
    func prepareForSnapshot() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = self
        window.makeKeyAndVisible()
    }
    
    func snapshotTestWithCase(_ testCase: FBSnapshotTestCase, referenceImagesDirectory: String, identifier: String) throws {

        try testCase.compareSnapshot(of: self.view, referenceImagesDirectory: referenceImagesDirectory, identifier: identifier, tolerance : StandardTolerance)
    }
    
    func finishSnapshot() {
        view.window?.removeFromSuperview()
    }
    
    var snapshotSize : CGSize {
        return view.bounds.size
    }
}

class SnapshotTestCase : FBSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        // Run "./gradlew recordSnapshots --continue" to regenerate all snapshots
        #if RECORD_SNAPSHOTS
            recordMode = true
        #endif
    }
    
    var screenSize : CGSize {
        // Standardize on a size so we don't have to worry about different simulators
        // etc.
        // Pick a non standard width so we can catch width assumptions.
        return CGSize(width: 380, height: 568)
    }
    
    fileprivate var majorVersion : Int {
        return ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }

    fileprivate final func qualifyIdentifier(_ identifier : String?, content : SnapshotTestable) -> String {
        let rtl = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? "_rtl" : ""
        let suffix = "ios\(majorVersion)\(rtl)_\(Int(content.snapshotSize.width))x\(Int(content.snapshotSize.height))"
        if let identifier = identifier {
            return identifier + suffix
        }
        else {
            return suffix
        }
    }
    
    // Asserts that a snapshot matches expectations
    // This is similar to the objc only FBSnapshotTest macros
    // But works in swift
    func assertSnapshotValidWithContent(_ content : SnapshotTestable, identifier : String? = nil, message : String? = nil, file : StaticString = #file, line : UInt = #line) {
        
        let qualifiedIdentifier = qualifyIdentifier(identifier, content : content)
        
        do {
            try content.snapshotTestWithCase(self, referenceImagesDirectory: SNAPSHOT_TEST_DIR, identifier: qualifiedIdentifier)
        }
        catch let error as NSError {
            XCTFail("Snapshot comparison failed (\(qualifiedIdentifier)): \(error.localizedDescription )", file : file, line : line)
            if let message = message {
                XCTFail(message, file : file, line : line)
            }
            else {
                XCTFail(file : file, line : line)
            }
        }
        XCTAssertFalse(recordMode, "Test ran in record mode. Reference image is now saved. Disable record mode to perform an actual snapshot comparison!", file : file, line : line)
    }
    
    func inScreenNavigationContext(_ controller : UIViewController, action : () -> ()) {
        let container = UINavigationController(rootViewController: controller)
        inScreenDisplayContext(container, action: action)
    }
    
    /// Makes a window and adds the controller to it
    /// to ensure that our controller actually loads properly
    /// Otherwise, sometimes viewWillAppear: type methods don't get called
    func inScreenDisplayContext(_ controller : UIViewController, action : () -> ()) {
        
        let window = UIWindow(frame: CGRect.zero)
        window.rootViewController = controller
        window.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        window.makeKeyAndVisible()
    
        controller.view.frame = window.bounds
        
        controller.view.updateConstraintsIfNeeded()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        action()
        
        window.removeFromSuperview()
    }
    
}
