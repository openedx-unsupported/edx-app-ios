//
//  ContentInsetsControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 7/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class ContentInsetsControllerTests: XCTestCase {
    
    var viewController : UIViewController!
    var scrollView : UIScrollView!
    var insetsController : ContentInsetsController!

    override func setUp() {
        super.setUp()
        insetsController = ContentInsetsController()
        viewController = UIViewController()
        scrollView = UIScrollView(frame: viewController.view.bounds)
        viewController.view.addSubview(scrollView)
        insetsController.setupInController(viewController, scrollView: scrollView)
    }
    
    func testExtraSource() {
        let insets = UIEdgeInsetsMake(20, 0, 20, 0)
        let source = ConstantInsetsSource(insets: insets, affectsScrollIndicators: false)
        insetsController.addSource(source)
        
        insetsController.updateInsets()
        XCTAssertEqual(scrollView.contentInset, insets)
        XCTAssertEqual(scrollView.scrollIndicatorInsets, UIEdgeInsetsZero)
    }
    
    func testSourcesSum() {
        var insets = UIEdgeInsetsMake(20, 0, 20, 0)
        insetsController.addSource(ConstantInsetsSource(insets: insets, affectsScrollIndicators: false))
        insets = UIEdgeInsetsMake(30, 0, 40, 0)
        insetsController.addSource(ConstantInsetsSource(insets: insets, affectsScrollIndicators: true))
        insetsController.updateInsets()
        XCTAssertEqual(scrollView.contentInset, UIEdgeInsetsMake(50, 0, 60, 0))
        XCTAssertEqual(scrollView.scrollIndicatorInsets, insets)
    }
    
    func testKeyboardOverridesBottom() {
        // Set up a normal insets
        let insets = UIEdgeInsetsMake(44, 0, 44, 0)
        insetsController.addSource(ConstantInsetsSource(insets: insets, affectsScrollIndicators: true))
        insetsController.updateInsets()
        XCTAssertEqual(scrollView.contentInset, insets)
        XCTAssertEqual(scrollView.scrollIndicatorInsets, insets)
        
        // now fire the keyboard
        let keyboardHeight : CGFloat = 100
        let intersectionHeight : CGFloat = 20
        var keyboardFrame = CGRectMake(0, viewController.view.bounds.size.height - keyboardHeight + intersectionHeight, viewController.view.bounds.size.width, keyboardHeight)
        var info : [NSObject:AnyObject] = [
            UIKeyboardAnimationCurveUserInfoKey : UIViewAnimationCurve.EaseInOut.rawValue as NSNumber,
            UIKeyboardAnimationDurationUserInfoKey : 0 as NSNumber,
            UIKeyboardFrameEndUserInfoKey : NSValue(CGRect : keyboardFrame)
        ]
        NSNotificationCenter.defaultCenter().postNotificationName(UIKeyboardDidChangeFrameNotification, object: nil, userInfo: info)
        
        // keyboard height should be used instead of insets bottom
        XCTAssertEqual(scrollView.contentInset, UIEdgeInsetsMake(insets.top, 0, keyboardHeight - intersectionHeight, 0))
        XCTAssertEqual(scrollView.scrollIndicatorInsets, UIEdgeInsetsMake(insets.top, 0, keyboardHeight - intersectionHeight, 0))
        
        // now lower the keyboard.
        
        keyboardFrame = CGRectMake(0, viewController.view.bounds.size.height, viewController.view.bounds.size.width, keyboardHeight)
        info = [
            UIKeyboardAnimationCurveUserInfoKey : UIViewAnimationCurve.EaseInOut.rawValue as NSNumber,
            UIKeyboardAnimationDurationUserInfoKey : 0 as NSNumber,
            UIKeyboardFrameEndUserInfoKey : NSValue(CGRect : keyboardFrame)
        ]
        NSNotificationCenter.defaultCenter().postNotificationName(UIKeyboardDidChangeFrameNotification, object: nil, userInfo: info)
        
        // insets.bottom should be back
        XCTAssertEqual(scrollView.contentInset, insets)
        XCTAssertEqual(scrollView.scrollIndicatorInsets, insets)
    }

}
