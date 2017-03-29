//
//  KeyboardInsetsSourceTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class KeyboardInsetsSourceTests: XCTestCase {
    
    var window : UIWindow?
    let scrollView = UIScrollView(frame : CGRect.zero)
    let keyboardHeight : CGFloat = 200
    
    override func setUp() {
        super.setUp()
        window = UIWindow()
        window?.frame = UIScreen.main.bounds
        scrollView.frame = UIScreen.main.bounds
        window?.addSubview(scrollView)
    }
    
    override func tearDown() {
        window?.removeFromSuperview()
    }
    
    func changeKeyboardLocation(_ height : CGFloat) {
        let y = scrollView.bounds.size.height - height
        let userInfo = [
            UIKeyboardFrameEndUserInfoKey : NSValue(cgRect : CGRect(x: 0, y: y, width: scrollView.bounds.size.width, height: keyboardHeight)),
            UIKeyboardAnimationDurationUserInfoKey : 0.3 as NSNumber,
            UIKeyboardAnimationCurveUserInfoKey : UIViewAnimationCurve.easeInOut.rawValue as NSNumber
        ]
        NotificationCenter.default.post(name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil, userInfo: userInfo)
    }
    
    func raiseKeyboard() {
        changeKeyboardLocation(keyboardHeight)
    }
    
    func lowerKeyboard() {
        changeKeyboardLocation(0)
    }

    func testKeyboardUp() {
        let source = KeyboardInsetsSource(scrollView : scrollView)
        raiseKeyboard()
        
        XCTAssertEqual(UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0), source.currentInsets)
    }
    
    func testKeyboardDown() {
        let source = KeyboardInsetsSource(scrollView : scrollView)
        raiseKeyboard()
        lowerKeyboard()
        XCTAssertEqual(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), source.currentInsets)
    }
    
}
