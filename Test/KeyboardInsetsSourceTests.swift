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
    let scrollView = UIScrollView(frame : CGRectZero)
    let keyboardHeight : CGFloat = 200
    
    override func setUp() {
        super.setUp()
        window = UIWindow()
        window?.frame = UIScreen.mainScreen().bounds
        scrollView.frame = UIScreen.mainScreen().bounds
        window?.addSubview(scrollView)
    }
    
    override func tearDown() {
        window?.removeFromSuperview()
    }
    
    func changeKeyboardLocation(height : CGFloat) {
        let y = scrollView.bounds.size.height - height
        let userInfo = [
            UIKeyboardFrameEndUserInfoKey : NSValue(CGRect : CGRectMake(0, y, scrollView.bounds.size.width, keyboardHeight)),
            UIKeyboardAnimationDurationUserInfoKey : 0.3 as NSNumber,
            UIKeyboardAnimationCurveUserInfoKey : UIViewAnimationCurve.EaseInOut.rawValue as NSNumber
        ]
        NSNotificationCenter.defaultCenter().postNotificationName(UIKeyboardDidChangeFrameNotification, object: nil, userInfo: userInfo)
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
