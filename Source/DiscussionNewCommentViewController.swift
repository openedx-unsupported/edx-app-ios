//
//  DiscussionNewCommentViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/5/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class DiscussionNewCommentViewController: UIViewController {
   
    @IBOutlet var newCommentView: UIView!
    @IBOutlet weak var newCommentScrollView: UIScrollView!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var answerTextView: UITextView!
    @IBOutlet weak var personTimeLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var addCommentButton: UIButton!
    
    @IBAction func addCommentTapped(sender: AnyObject) {
    }
}
