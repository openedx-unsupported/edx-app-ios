//
//  DiscussionNewPostViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


class DiscussionNewPostViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    
    init(router: OEXRouter?) {
        self.router = router
    }
}


class UITapGestureRecognizerWithClosure: NSObject {
    var closure: () -> ()
    
    init(view: UIView, tapGestureRecognizer: UITapGestureRecognizer, closure: () -> ()) {
        self.closure = closure
        super.init()
        view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action:Selector("actionFired:"))
    }
    
    func actionFired(tapGestureRecognizer: UITapGestureRecognizer) {
        self.closure()
    }
}

class DiscussionNewPostViewController: UIViewController, UITextViewDelegate {
    
    private var tapWrapper:UITapGestureRecognizerWithClosure?
    
    private let MIN_HEIGHT : CGFloat = 66 // height for 3 lines of text
    private let environment: DiscussionNewPostViewControllerEnvironment
    private let insetsController = ContentInsetsController()
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var backgroundView: UIView!

    @IBOutlet var newPostView: UIView!
    @IBOutlet var contentTextView: UITextView!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var discussionQuestionSegmentedControl: UISegmentedControl!
    @IBOutlet var bodyTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var topicButton: UIButton!
    @IBOutlet var postDiscussionButton: UIButton!
    private let course: OEXCourse
    
    init(env: DiscussionNewPostViewControllerEnvironment, course: OEXCourse) {
        self.environment = env
        self.course = course
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func postTapped(sender: AnyObject) {
        postDiscussionButton.enabled = false
        // create new thread (post)
        let json = JSON([
            "course_id" : course.course_id,
            "topic_id" : "b770140a122741fea651a50362dee7e6", // TODO: replace this with real topic ID, selectable from the Topic dropdown in Create a new post UI.
            "type" : "discussion",
            "title" : titleTextField.text,
            "raw_body" : contentTextView.text,
            ])
        
        let apiRequest = DiscussionAPI.createNewThread(json)
        
//        let apiRequest = NetworkRequest(
//            method : HTTPMethod.POST,
//            path : "/api/discussion/v1/threads/",
//            requiresAuth : true,
//            body: RequestBody.JSONBody(json),
//            deserializer : {(response, data) -> Result<NSObject> in
//                var dataString = NSString(data: data!, encoding:NSUTF8StringEncoding)
//                #if DEBUG
//                    println("\(response), \(dataString)")
//                #endif
//
//                return Failure(nil)
//            })
        
        environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
            self.navigationController?.popViewControllerAnimated(true)
            self.postDiscussionButton.enabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSBundle.mainBundle().loadNibNamed("DiscussionNewPostView", owner: self, options: nil)
        view.addSubview(newPostView)
        newPostView?.autoresizingMask =  UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleLeftMargin
        newPostView?.frame = view.frame
        
        contentTextView.layer.cornerRadius = 10
        contentTextView.layer.masksToBounds = true
        contentTextView.delegate = self
        backgroundView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        discussionQuestionSegmentedControl.setTitle(OEXLocalizedString("DISCUSSION", nil), forSegmentAtIndex: 0)
        discussionQuestionSegmentedControl.setTitle(OEXLocalizedString("QUESTION", nil), forSegmentAtIndex: 1)
        titleTextField.placeholder = OEXLocalizedString("TITLE", nil)
        topicButton.setTitle(OEXLocalizedString("TOPIC", nil), forState: .Normal)
        postDiscussionButton.setTitle(OEXLocalizedString("POST_DISCUSSION", nil), forState: .Normal)
        
        tapWrapper = UITapGestureRecognizerWithClosure(view: self.newPostView, tapGestureRecognizer: UITapGestureRecognizer()) {
            self.contentTextView.resignFirstResponder()
            self.titleTextField.resignFirstResponder()
        }

        self.insetsController.setupInController(self, scrollView: scrollView)
        
        getCourseTopics()
    }
    
    func getCourseTopics() {
        if let courseID = self.course.course_id {
            let apiRequest = NetworkRequest(
                method : HTTPMethod.GET,
                path : "/api/discussion/v1/course_topics/\(courseID)",
                requiresAuth : true,
                deserializer : {(response, data) -> Result<NSObject> in
                    var dataString = NSString(data: data!, encoding:NSUTF8StringEncoding)
                    
                    #if DEBUG
                        println("\(response), \(dataString)")
                    #endif
                    
                    let json = JSON(data: data!)
                    //                if let results = json["results"].array {
                    //                    self.topics.removeAll(keepCapacity: true)
                    //                    for result in results {
                    //                        if  let body = result["raw_body"].string,
                    //                            let author = result["author"].string,
                    //                            let createdAt = result["created_at"].string,
                    //                            let responseID = result["id"].string,
                    //                            let threadID = result["thread_id"].string,
                    //                            let children = result["children"].array {
                    //
                    //                                let voteCount = result["vote_count"].int ?? 0
                    //                                let item = DiscussionResponseItem(
                    //                                    body: body,
                    //                                    author: author,
                    //                                    createdAt: OEXDateFormatting.dateWithServerString(createdAt),
                    //                                    voteCount: voteCount,
                    //                                    responseID: responseID,
                    //                                    threadID: threadID,
                    //                                    children: children)
                    //                                
                    //                                self.responses.append(item)
                    //                        }
                    //                    }
                    //                }
                    return Failure(nil)
            })
            
            environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
            }
        }
    }
    
    func viewTapped(sender: UITapGestureRecognizer) {
        contentTextView.resignFirstResponder()
        titleTextField.resignFirstResponder()
    }
    
    func textViewDidChange(textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        if newSize.height >= MIN_HEIGHT {
            bodyTextViewHeightConstraint.constant = newSize.height
        }
    }
}
