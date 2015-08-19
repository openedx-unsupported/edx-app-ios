//
//  GrowingTextViewController.swift
//  edX
//
//  Created by Akiva Leffert on 8/17/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

/// Supports a text view nested inside of a scroll view, where the text view is sized to fit its entire content.
/// Updates the ``contentOffset`` of the scroll view to track typing
/// and the ``contentSize`` of the scroll view to track resizing.
///
/// To use:
///
/// 1. Set up your view so that its height depends on the text view's ``intrinsicContentSize``.
///
/// 2. Create one of these controllers.
///
/// 3. Call the public methods on this from your view controller  as described on each method.

public class GrowingTextViewController {
    
    private var scrollView : UIScrollView?
    private var textView : UITextView?
    private var bottomView : UIView?
    
    private var textUpdating = false

    /// Call from viewDidLoad
    public func setupWithScrollView(scrollView : UIScrollView, textView : UITextView, bottomView : UIView) {
        textView.scrollEnabled = false
        self.scrollView = scrollView
        self.textView = textView
        self.bottomView = bottomView
    }
    
    /// Call from inside textViewDidChange: in your text view's delegate
    public func handleTextChange() {
        textUpdating = true
        self.scrollView?.setNeedsLayout()
        self.scrollView?.layoutIfNeeded()
        textUpdating = false
    }
    
    /// Call from viewDidLayoutSubviews in your view controller
    public func scrollToVisible() {
        if let scrollView = self.scrollView,
            textView = self.textView,
            range = textView.selectedTextRange
        {
            let rect = textView.caretRectForPosition(range.end)
            let scrollRect = scrollView.convertRect(rect, fromView:textView)
            let offsetRect = CGRectOffset(scrollRect, 0, 10) // add a little margin for the text
            scrollView.scrollRectToVisible(offsetRect, animated: true)
            
            if let bottomView = self.bottomView {
                // If we just made a new line of text, the bottom position might not actually be updated
                // yet when we get here
                // So, wait until the next run loop to update the contentSize.
                dispatch_async(dispatch_get_main_queue()) {
                    let buttonFrame = scrollView.convertRect(bottomView.bounds, fromView:bottomView)
                    scrollView.contentSize = CGSizeMake(scrollView.bounds.size.width, buttonFrame.maxY + OEXStyles.sharedStyles().standardHorizontalMargin())
                }
            }

        }
    }
}
