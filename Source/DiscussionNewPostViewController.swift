//
//  DiscussionNewPostViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class DiscussionNewPostViewController: UIViewController {
    var uiview:UIView?
    
    @IBOutlet weak var contentTextView: UITextView!
    
    @IBAction func postTapped(sender: AnyObject) {
    }
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uiview = NSBundle.mainBundle().loadNibNamed("DiscussionNewPostView", owner: self, options: nil)[0] as? UIView
        uiview!.frame = self.view.frame
        view.addSubview(self.uiview!)
        
        contentTextView.layer.cornerRadius = 10
        contentTextView.layer.masksToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "viewTapped:")
        view.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "handleKeyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: "handleKeyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func viewTapped(sender: UITapGestureRecognizer) {
        contentTextView.resignFirstResponder()
    }
    
    
    func handleKeyboardWillShow(notification: NSNotification) {
        // why animation doesn't seem to work?
        UIView.animateWithDuration(2.5, animations: {[weak self] in
            self?.heightConstraint.constant = 100
        })
    }
    
    func handleKeyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(2.5, animations: {[weak self] in
            self?.heightConstraint.constant = 150
        })
    }

}
