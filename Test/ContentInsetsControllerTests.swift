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
        insetsController.setupInController(owner: viewController, scrollView: scrollView)
    }
    
    func testExtraSource() {
        let insets = UIEdgeInsets.init(top: 20, left: 0, bottom: 20, right: 0)
        let source = ConstantInsetsSource(insets: insets, affectsScrollIndicators: false)
        insetsController.addSource(source: source)
        
        insetsController.updateInsets()
        XCTAssertEqual(scrollView.contentInset, insets)
        XCTAssertEqual(scrollView.horizontalScrollIndicatorInsets, UIEdgeInsets.zero)
        XCTAssertEqual(scrollView.verticalScrollIndicatorInsets, UIEdgeInsets.zero)
    }
    
    func testSourcesSum() {
        var insets = UIEdgeInsets.init(top: 20, left: 0, bottom: 20, right: 0)
        insetsController.addSource(source: ConstantInsetsSource(insets: insets, affectsScrollIndicators: false))
        insets = UIEdgeInsets.init(top: 30, left: 0, bottom: 40, right: 0)
        insetsController.addSource(source: ConstantInsetsSource(insets: insets, affectsScrollIndicators: true))
        insetsController.updateInsets()
        XCTAssertEqual(scrollView.contentInset, UIEdgeInsets.init(top: 50, left: 0, bottom: 60, right: 0))
        XCTAssertEqual(scrollView.horizontalScrollIndicatorInsets, insets)
        XCTAssertEqual(scrollView.verticalScrollIndicatorInsets, insets)
    }
    
    func testKeyboardOverridesBottom() {
        // Set up a normal insets
        let insets = UIEdgeInsets.init(top: 44, left: 0, bottom: 44, right: 0)
        insetsController.addSource(source: ConstantInsetsSource(insets: insets, affectsScrollIndicators: true))
        insetsController.updateInsets()
        XCTAssertEqual(scrollView.contentInset, insets)
        XCTAssertEqual(scrollView.horizontalScrollIndicatorInsets, insets)
        XCTAssertEqual(scrollView.verticalScrollIndicatorInsets, insets)
        
        // now fire the keyboard
        let keyboardHeight : CGFloat = 100
        let intersectionHeight : CGFloat = 20
        var keyboardFrame = CGRect(x: 0, y: viewController.view.bounds.size.height - keyboardHeight + intersectionHeight, width: viewController.view.bounds.size.width, height: keyboardHeight)
        var info : [AnyHashable: Any] = [
            UIResponder.keyboardAnimationCurveUserInfoKey : UIView.AnimationCurve.easeInOut.rawValue as NSNumber,
            UIResponder.keyboardAnimationDurationUserInfoKey : 0 as NSNumber,
            UIResponder.keyboardFrameEndUserInfoKey : NSValue(cgRect : keyboardFrame)
        ]
        NotificationCenter.default.post(name: UIResponder.keyboardDidChangeFrameNotification, object: nil, userInfo: info)
        
        // keyboard height should be used instead of insets bottom
        XCTAssertEqual(scrollView.contentInset, UIEdgeInsets.init(top: insets.top, left: 0, bottom: keyboardHeight - intersectionHeight, right: 0))
        XCTAssertEqual(scrollView.horizontalScrollIndicatorInsets, UIEdgeInsets.init(top: insets.top, left: 0, bottom: keyboardHeight - intersectionHeight, right: 0))
        XCTAssertEqual(scrollView.verticalScrollIndicatorInsets, UIEdgeInsets.init(top: insets.top, left: 0, bottom: keyboardHeight - intersectionHeight, right: 0))
        
        // now lower the keyboard.
        
        keyboardFrame = CGRect(x: 0, y: viewController.view.bounds.size.height, width: viewController.view.bounds.size.width, height: keyboardHeight)
        info = [
            UIResponder.keyboardAnimationCurveUserInfoKey : UIView.AnimationCurve.easeInOut.rawValue as NSNumber,
            UIResponder.keyboardAnimationDurationUserInfoKey : 0 as NSNumber,
            UIResponder.keyboardFrameEndUserInfoKey : NSValue(cgRect : keyboardFrame)
        ]
        NotificationCenter.default.post(name: UIResponder.keyboardDidChangeFrameNotification, object: nil, userInfo: info)
        
        // insets.bottom should be back
        XCTAssertEqual(scrollView.contentInset, insets)
        XCTAssertEqual(scrollView.horizontalScrollIndicatorInsets, insets)
        XCTAssertEqual(scrollView.verticalScrollIndicatorInsets, insets)
    }

}
