//
//  DiscussionResponsesViewController.swift
//  edX
//
//  Created by Lim, Jake on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

enum DiscussionItem {
    case Post(DiscussionPostItem)
    case Response(DiscussionResponseItem)
    
    var threadID : String {
        switch self {
            case let .Post(item): return item.threadID
            case let .Response(item): return item.threadID
        }
    }
    
    var responseID : String {
        switch self {
            case let .Post(item): return ""
            case let .Response(item): return item.responseID
        }
    }
    
    var title: String {
        switch self {
            case let .Post(item): return item.title
            case let .Response(item): return ""
        }
    }
    
    var body: String {
        switch self {
        case let .Post(item): return item.body
        case let .Response(item): return item.body
        }
    }
    
    var createdAt: NSDate {
        switch self {
        case let .Post(item): return item.createdAt
        case let .Response(item): return item.createdAt
        }
    }
    
    var author: String {
        switch self {
        case let .Post(item): return item.author
        case let .Response(item): return item.author
        }
    }
}

struct DiscussionResponseItem {
    let body: String
    let author: String
    let createdAt: NSDate
    let voteCount: Int
    let responseID: String
    let threadID: String
    let children: [JSON]
}

private let GENERAL_PADDING: CGFloat = 8.0
private var CellButtonStyle = OEXTextStyle().withSize(.Base).withColor(OEXStyles.sharedStyles().primaryBaseColor())

class CellButton: UIButton {
    var row: Int?
}

class DiscussionPostCell: UITableViewCell {
    static let identifier = "DiscussionPostCell"

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bodyTextLabel: UILabel!
    @IBOutlet var visibilityLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var responseCountLabel:UILabel!
    @IBOutlet var voteButton: UIButton!
    @IBOutlet var followButton: UIButton!
    @IBOutlet var reportButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        for (button, icon, text) in [
            (voteButton, Icon.UpVote, "2 Votes"), // TODO: put in real data
            (followButton, Icon.FollowStar, OEXLocalizedString("DISCUSSION_FOLLOW", nil)),
            (reportButton, Icon.ReportFlag, OEXLocalizedString("DISCUSSION_REPORT", nil))
            ]
        {
            let buttonText = NSAttributedString.joinInNaturalLayout(
                before: icon.attributedTextWithStyle(CellButtonStyle),
                after: CellButtonStyle.attributedStringWithText(text))
            button.setAttributedTitle(buttonText, forState:.Normal)
        }
    }
}

class DiscussionResponseCell: UITableViewCell {
    static let identifier = "DiscussionResponseCell"
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var bodyTextLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var voteButton: UIButton!
    @IBOutlet var reportButton: UIButton!
    @IBOutlet weak var bubbleIconButton: CellButton!
    @IBOutlet weak var commentButton: CellButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        for (button, icon, text) in [
            (voteButton, Icon.UpVote, "2 Votes"), // TODO: put in real data
            (bubbleIconButton, Icon.Comment, nil),
            (reportButton, Icon.ReportFlag, OEXLocalizedString("DISCUSSION_REPORT", nil))]
        {
            let iconString = icon.attributedTextWithStyle(CellButtonStyle)
            let buttonText : NSAttributedString
            if let text = text {
                buttonText = NSAttributedString.joinInNaturalLayout(
                before: iconString,
                after: CellButtonStyle.attributedStringWithText(text))
            }
            else {
                buttonText = iconString
            }
            button.setAttributedTitle(buttonText, forState:.Normal)
        }

        containerView.layer.cornerRadius = 5;
        containerView.layer.masksToBounds = true;
    }
}

class DiscussionResponsesViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    
    init(router: OEXRouter?) {
        self.router = router
    }
}


class DiscussionResponsesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var environment: DiscussionResponsesViewControllerEnvironment!
    @IBOutlet var tableView: UITableView!
    private let addResponseButton = UIButton.buttonWithType(.System) as! UIButton
    private var responses : [DiscussionResponseItem]  = []
    var postItem: DiscussionPostItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralBase()
        
        tableView.backgroundColor = UIColor.clearColor()
        tableView.delegate = self
        tableView.dataSource = self
        
        addResponseButton.backgroundColor = OEXStyles.sharedStyles().neutralDark()

        let style = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralWhite())
        let buttonTitle = NSAttributedString.joinInNaturalLayout(
            before: Icon.Create.attributedTextWithStyle(style.withSize(.XSmall)),
            after: style.attributedStringWithText(OEXLocalizedString("ADD_A_RESPONSE", nil)))
        addResponseButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
        addResponseButton.contentVerticalAlignment = .Center
        
        weak var weakSelf = self
        addResponseButton.oex_addAction({ (action : AnyObject!) -> Void in
            environment.router?.showDiscussionNewCommentFromController(weakSelf!, isResponse: true, item: DiscussionItem.Post(weakSelf!.postItem!))
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
            path : "/api/discussion/v1/comments/?page_size=20&thread_id=\(postItem!.threadID)", // responses are treated similarly as comments
            requiresAuth : true,
            deserializer : {(response, data) -> Result<NSObject> in
                var dataString = NSString(data: data!, encoding:NSUTF8StringEncoding)
                
                #if DEBUG
                    println("\(response), \(dataString)")
                #endif
                    
                let json = JSON(data: data!)
                if let results = json["results"].array {
                    self.responses.removeAll(keepCapacity: true)
                    for result in results {
                        if  let body = result["raw_body"].string,
                            let author = result["author"].string,
                            let createdAt = result["created_at"].string,
                            let responseID = result["id"].string,
                            let threadID = result["thread_id"].string,
                            let children = result["children"].array {
                                
                                let voteCount = result["vote_count"].int ?? 0
                                let item = DiscussionResponseItem(
                                    body: body,
                                    author: author,
                                    createdAt: OEXDateFormatting.dateWithServerString(createdAt),
                                    voteCount: voteCount,
                                    responseID: responseID,
                                    threadID: threadID,
                                    children: children)
                                
                                self.responses.append(item)
                        }
                    }
                }
                return Failure(nil)
        })
        
        environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
            self.tableView.reloadData()
        }
    }
    
    
    @IBAction func commentTapped(sender: AnyObject) {
        if let button = sender as? CellButton, row = button.row {
            environment.router?.showDiscussionCommentsFromViewController(self, item: responses[row])
        }
    }
    
    // Mark - tableview delegate methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return responses.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionPostCell.identifier, forIndexPath: indexPath) as! DiscussionPostCell
            if let item = postItem {
                cell.titleLabel.text = item.title
                cell.bodyTextLabel.text = item.body
                cell.visibilityLabel.text = "" // This post is visible to cohort test" // TODO: figure this out
                cell.authorLabel.text = DateHelper.socialFormatFromDate(item.createdAt) +  " " + item.author
            }
            cell.responseCountLabel.text = "\(responses.count) response" + (responses.count == 1 ? "" : "s")
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionResponseCell.identifier, forIndexPath: indexPath) as! DiscussionResponseCell
            cell.bodyTextLabel.text = responses[indexPath.row].body
            cell.authorLabel.text = DateHelper.socialFormatFromDate(responses[indexPath.row].createdAt) +  " " + responses[indexPath.row].author
            let commentCount = responses[indexPath.row].children.count
            cell.commentButton.setTitle("\(commentCount) Comment" + (commentCount==1 ? "" : "s") + " to this response", forState: .Normal)
            let voteCount = responses[indexPath.row].voteCount
            cell.commentButton.row = indexPath.row
            cell.bubbleIconButton.row = indexPath.row
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