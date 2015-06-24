//
//  DiscussionNewCommentViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/5/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol NewCommentDelegate : class {
    func updateComments(item: DiscussionResponseItem)
}

class DiscussionNewCommentViewControllerEnvironment: DiscussionItem {
    weak var router: OEXRouter?
    var item: DiscussionItem?
    
    init(router: OEXRouter?, item: DiscussionItem?) {
        self.router = router
        self.item = item
    }
}


class DiscussionNewCommentViewController: UIViewController, UITextViewDelegate {
    private var tapWrapper:UITapGestureRecognizerWithClosure?
    private let MIN_HEIGHT: CGFloat = 66 // height for 3 lines of text
    private let environment: DiscussionNewCommentViewControllerEnvironment
    private var addAComment: String {
        get {
            return OEXLocalizedString("ADD_A_COMMENT", nil)
        }
    }
    private var addAResponse: String {
        get {
            return OEXLocalizedString("ADD_A_RESPONSE", nil)
        }
    }
    weak var delegate​: NewCommentDelegate?
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var backgroundView: UIView!

    @IBOutlet var newCommentView: UIView!
    @IBOutlet var answerLabel: UILabel!
    @IBOutlet var answerTextView: UITextView!
    @IBOutlet var personTimeLabel: UILabel!
    @IBOutlet var contentTextView: UITextView!
    @IBOutlet var addCommentButton: UIButton!
    @IBOutlet var contentTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var answerTextViewHeightConstraint: NSLayoutConstraint!
    
    var isResponse: Bool
    
    @IBAction func addCommentTapped(sender: AnyObject) {
        addCommentButton.enabled = false
        
        // create new response or comment
        var json = JSON([
            "thread_id" : isResponse ? (environment.item as! DiscussionPostItem).threadID : (environment.item as! DiscussionResponseItem).threadID,
            "raw_body" : contentTextView.text,
            ])
        if !isResponse {
            json["parent_id"] = JSON((environment.item as! DiscussionResponseItem).responseID)
        }
        let apiRequest = NetworkRequest(
            method : HTTPMethod.POST,
            path : "/api/discussion/v1/comments/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : {(response, data) -> Result<NSObject> in
                var dataString = NSString(data: data!, encoding:NSUTF8StringEncoding)
                println("\(response), \(dataString)")
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.navigationController?.popViewControllerAnimated(true)
                    self.addCommentButton.enabled = false
                    let json = JSON(data: data!)
                    let item = DiscussionResponseItem(
                        body: json["raw_body"].string!,
                        author: json["author"].string!,
                        createdAt: OEXDateFormatting.dateWithServerString(json["created_at"].string!),
                        voteCount: json["vote_count"].int!,
                        responseID: json["id"].string!,
                        threadID: json["thread_id"].string!,
                        children: [])
                    self.delegate​?.updateComments(item)
                }
                
                return Failure(nil)
        })
        
        environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
            println("\(result.data)")
        }
    }
    
    
    init(env: DiscussionNewCommentViewControllerEnvironment, isResponse: Bool) {
        self.environment = env
        self.isResponse = isResponse
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSBundle.mainBundle().loadNibNamed("DiscussionNewCommentView", owner: self, options: nil)
        view.addSubview(newCommentView)
        newCommentView?.autoresizingMask =  UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleLeftMargin
        newCommentView?.frame = view.frame
        
        if isResponse {
            let item = environment.item as! DiscussionPostItem
            answerLabel.text = item.title
            answerTextView.text = item.body
            personTimeLabel.text = DateHelper.socialFormatFromDate(item.createdAt) +  " " + item.author
            addCommentButton.setTitle(OEXLocalizedString("ADD_RESPONSE", nil), forState: .Normal)
            // add place holder for the textview
            contentTextView.text = addAResponse
        }
        else {
            let item = environment.item as! DiscussionResponseItem
            answerLabel.font = Icon.fontWithSize(12)
            answerLabel.text = OEXLocalizedString("ANSWER", nil).textWithIconFont(Icon.Answered.textRepresentation)
            answerTextView.text = item.body
            personTimeLabel.text = DateHelper.socialFormatFromDate(item.createdAt) +  " " + item.author
            addCommentButton.setTitle(OEXLocalizedString("ADD_COMMENT", nil), forState: .Normal)
            // add place holder for the textview
            contentTextView.text = addAComment
        }
        answerLabel.textColor = OEXStyles.sharedStyles().utilitySuccessBase()
        answerTextView.textColor = OEXStyles.sharedStyles().neutralDark()
        
        let fixedWidth = answerTextView.frame.size.width
        let newSize = answerTextView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        answerTextViewHeightConstraint.constant = newSize.height
        
        personTimeLabel.textColor = OEXStyles.sharedStyles().neutralBase()
        
        contentTextView.textColor = OEXStyles.sharedStyles().neutralBase()
        
        backgroundView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        contentTextView.layer.cornerRadius = 10
        contentTextView.layer.masksToBounds = true
        contentTextView.delegate = self
        
        tapWrapper = UITapGestureRecognizerWithClosure(view: self.newCommentView, tapGestureRecognizer: UITapGestureRecognizer()) {
            [weak self] in
            self?.contentTextView.resignFirstResponder()
        }
        
        handleKeyboard(scrollView, backgroundView)
    }
    
    func viewTapped(sender: UITapGestureRecognizer) {
        contentTextView.resignFirstResponder()
    }
    
    func textViewDidChange(textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        if newSize.height >= MIN_HEIGHT {
            contentTextViewHeightConstraint.constant = newSize.height
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == addAComment || textView.text == addAResponse {
            textView.text = ""
            textView.textColor = OEXStyles.sharedStyles().neutralBlack()
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = isResponse ? addAResponse : addAComment
            textView.textColor = OEXStyles.sharedStyles().neutralLight()
        }
        textView.resignFirstResponder()
    }
    
}
