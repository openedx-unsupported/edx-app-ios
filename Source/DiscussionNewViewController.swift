//
//  DiscussionNewViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class DiscussionNewViewController: UIViewController {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var backgroundView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func handleKeyboard() {
        NSNotificationCenter.defaultCenter().oex_addObserver(self, notification: UIKeyboardWillChangeFrameNotification) { (notification : NSNotification!, observer : AnyObject!, removeable : OEXRemovable!) -> Void in
            if let vc = observer as? DiscussionNewViewController {
                if let info = notification.userInfo {
                    let keyboardEndRectObject = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
                    var keyboardEndRect = keyboardEndRectObject.CGRectValue()
                    keyboardEndRect = vc.view.convertRect(keyboardEndRect, fromView: nil)
                    let intersectionOfKeyboardRectAndWindowRect = CGRectIntersection(vc.view.frame, keyboardEndRect)
                    vc.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: intersectionOfKeyboardRectAndWindowRect.size.height, right: 0)
                    if vc.scrollView.contentOffset.y == 0 {
                        vc.scrollView.contentOffset = CGPointMake(0, vc.backgroundView.frame.origin.y)
                    }
                    else {
                        vc.scrollView.contentOffset = CGPointZero
                    }
                }
            }
        }
    }
}
