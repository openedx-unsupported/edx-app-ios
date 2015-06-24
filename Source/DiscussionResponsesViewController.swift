//
//  DiscussionResponsesViewController.swift
//  edX
//
//  Created by Lim, Jake on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let GENERAL_PADDING: CGFloat = 8.0

protocol DiscussionItem {
}

struct DiscussionResponseItem: DiscussionItem {
    let body: String
    let author: String
    let createdAt: NSDate
    let voteCount: Int
    let responseID: String
    let threadID: String
    let children: [JSON]
}


class DiscussionPostCell: UITableViewCell {
    static let identifier = "DiscussionPostCell"

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bodyTextLabel: UILabel!
    @IBOutlet var visibilityLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var responseCountLabel:UILabel!
    @IBOutlet var plusIconButton: UIButton!
    @IBOutlet var voteButton: UIButton!
    @IBOutlet var starIconButton: UIButton!
    @IBOutlet var followButton: UIButton!
    @IBOutlet var flagIconButton: UIButton!
    @IBOutlet var reportButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        plusIconButton.titleLabel?.font = Icon.fontWithSize(15)
        plusIconButton.setTitle(Icon.UpVote.textRepresentation, forState: .Normal)
        plusIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        
        starIconButton.titleLabel?.font = Icon.fontWithSize(15)
        starIconButton.setTitle(Icon.FollowStar.textRepresentation, forState: .Normal)
        starIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        
        flagIconButton.titleLabel?.font = Icon.fontWithSize(15)
        flagIconButton.setTitle(Icon.ReportFlag.textRepresentation, forState: .Normal)
        flagIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
    }
}

class DiscussionResponseCell: UITableViewCell {
    static let identifier = "DiscussionResponseCell"
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var bodyTextLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var plusIconButton: UIButton!
    @IBOutlet var voteButton: UIButton!
    @IBOutlet var flagIconButton: UIButton!
    @IBOutlet var reportButton: UIButton!
    @IBOutlet var bubbleIconButton: UIButton!
    @IBOutlet var commentButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        plusIconButton.titleLabel?.font = Icon.fontWithSize(15)
        plusIconButton.setTitle(Icon.UpVote.textRepresentation, forState: .Normal)
        plusIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        
        flagIconButton.titleLabel?.font = Icon.fontWithSize(15)
        flagIconButton.setTitle(Icon.ReportFlag.textRepresentation, forState: .Normal)
        flagIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        
        bubbleIconButton.titleLabel?.font = Icon.fontWithSize(15)
        bubbleIconButton.setTitle(Icon.Comment.textRepresentation, forState: .Normal)
        bubbleIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)

        containerView.layer.cornerRadius = 5;
        containerView.layer.masksToBounds = true;
    }
}

class DiscussionResponsesViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    let postItem: DiscussionPostItem
    
    init(router: OEXRouter?, postItem: DiscussionPostItem) {
        self.router = router
        self.postItem = postItem
    }
}


class DiscussionResponsesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var environment: DiscussionResponsesViewControllerEnvironment!
    @IBOutlet var tableView: UITableView!
    private let addResponseButton = UIButton.buttonWithType(.System) as! UIButton
    private var responses : [DiscussionResponseItem]  = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralBase()
        
        tableView.backgroundColor = UIColor.clearColor()
        tableView.delegate = self
        tableView.dataSource = self
        
        addResponseButton.backgroundColor = OEXStyles.sharedStyles().neutralDark()

        let createAPostString = OEXLocalizedString("ADD_A_RESPONSE", nil)
        let plainText = createAPostString.textWithIconFont(Icon.Create.textRepresentation)
        let styledText = NSMutableAttributedString(string: plainText)
        styledText.setSizeForText(plainText, textSizes: [createAPostString: 16, Icon.Create.textRepresentation: 12])
        styledText.addAttribute(NSForegroundColorAttributeName, value: OEXStyles.sharedStyles().neutralWhite(), range: NSMakeRange(0, count(plainText)))
        
        addResponseButton.setAttributedTitle(styledText, forState: .Normal)
        addResponseButton.contentVerticalAlignment = .Center
        
        weak var weakSelf = self
        addResponseButton.oex_addAction({ (action : AnyObject!) -> Void in
            environment.router?.showDiscussionNewCommentFromController(weakSelf!, isResponse: true, item: weakSelf!.environment.postItem)
        }, forEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(addResponseButton)
        addResponseButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(60)
            make.bottom.equalTo(view.snp_bottom)
        }        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        getAndShowResponses()
    }
    
    func getAndShowResponses() {
        let apiRequest = NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/comments/?page_size=20&thread_id=\(environment.postItem.threadID)", // responses are treated similarly as comments
            requiresAuth : true,
            deserializer : {(response, data) -> Result<NSObject> in
                var dataString = NSString(data: data!, encoding:NSUTF8StringEncoding)
                println("\(response), \(dataString)")
                
                let json = JSON(data: data!)
                if let results = json["results"].array {
                    self.responses.removeAll(keepCapacity: true)
                    for result in results {
                        let item = DiscussionResponseItem(
                            body: result["raw_body"].string!,
                            author: result["author"].string!,
                            createdAt: OEXDateFormatting.dateWithServerString(result["created_at"].string!),
                            voteCount: result["vote_count"].int!,
                            responseID: result["id"].string!,
                            threadID: result["thread_id"].string!,
                            children: result["children"].array!)
                        
                        self.responses.append(item)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
                return Failure(nil)
        })
        
        environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
            println("\(result.data)")
        }
    }
    
    
    @IBAction func commentTapped(sender: AnyObject) {
        environment.router?.showDiscussionCommentsFromViewController(self, item: responses[sender.tag])
    }
    
    // Mark - tableview delegate methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            println("responses.count: \(responses.count)")
            return responses.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionPostCell.identifier, forIndexPath: indexPath) as! DiscussionPostCell

            cell.titleLabel.text = environment.postItem.title
            cell.bodyTextLabel.text = environment.postItem.body
            cell.visibilityLabel.text = "" // This post is visible to cohort test" // TODO: figure this out
            cell.authorLabel.text = DateHelper.socialFormatFromDate(environment.postItem.createdAt) +  " " + environment.postItem.author
            cell.responseCountLabel.text = "\(responses.count) response" + (responses.count == 1 ? "" : "s")
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionResponseCell.identifier, forIndexPath: indexPath) as! DiscussionResponseCell
            cell.bodyTextLabel.text = responses[indexPath.row].body
            cell.authorLabel.text = DateHelper.socialFormatFromDate(responses[indexPath.row].createdAt) +  " " + responses[indexPath.row].author
            let commentCount = responses[indexPath.row].children.count
            cell.commentButton.setTitle("\(commentCount) Comment" + (commentCount==1 ? "" : "s") + " to this response", forState: .Normal)
            let voteCount = responses[indexPath.row].voteCount
            cell.commentButton.tag = indexPath.row
            cell.voteButton.setTitle("\(voteCount) vote" + (voteCount==1 ? "" : "s"), forState: .Normal)
            return cell
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section != 0 {
            cell.backgroundColor = UIColor.clearColor()
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 200.0
        } else {
            return 210.0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // TODO
    }
}