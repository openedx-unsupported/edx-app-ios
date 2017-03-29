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
        textView.isScrollEnabled = false
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
            let textView = self.textView,
            let range = textView.selectedTextRange
        {
            let rect = textView.caretRect(for: range.end)
            let scrollRect = scrollView.convert(rect, from:textView)
            let offsetRect = scrollRect.offsetBy(dx: 0, dy: 10) // add a little margin for the text
            scrollView.scrollRectToVisible(offsetRect, animated: true)
            
            if let bottomView = self.bottomView {
                // If we just made a new line of text, the bottom position might not actually be updated
                // yet when we get here
                // So, wait until the next run loop to update the contentSize.
                DispatchQueue.main.async {
                    let buttonFrame = scrollView.convert(bottomView.bounds, from:bottomView)
                    scrollView.contentSize = CGSize(width:scrollView.bounds.size.width, height: buttonFrame.maxY + StandardHorizontalMargin)
                }
            }

        }
    }
}
