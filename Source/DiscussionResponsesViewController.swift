//
//  DiscussionResponsesViewController.swift
//  edX
//
//  Created by Lim, Jake on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let GENERAL_PADDING: CGFloat = 8.0

private var CellButtonStyle = OEXTextStyle().withSize(15).withColor(OEXStyles.sharedStyles().primaryBaseColor())

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
    @IBOutlet var bubbleIconButton: UIButton!
    @IBOutlet var commentButton: UIButton!
    
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
    private let tableView: UITableView = UITableView()
    private let addResponseButton = UIButton.buttonWithType(.System) as! UIButton
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralBase()
        
        tableView.backgroundColor = UIColor.clearColor()
        
        addResponseButton.backgroundColor = OEXStyles.sharedStyles().neutralDark()

        let style = OEXTextStyle(font: .ThemeSans, size: 16, color: OEXStyles.sharedStyles().neutralWhite())
        let buttonTitle = NSAttributedString.joinInNaturalLayout(
            before: Icon.Create.attributedTextWithStyle(style.withSize(12)),
            after: style.attributedStringWithText(OEXLocalizedString("ADD_A_RESPONSE", nil)))
        addResponseButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
        addResponseButton.contentVerticalAlignment = .Center
        
        weak var weakSelf = self
        addResponseButton.oex_addAction({ (action : AnyObject!) -> Void in
            environment.router?.showDiscussionNewCommentFromController(weakSelf, isResponse: true)
            }, forEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(addResponseButton)
        addResponseButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(60)
            make.bottom.equalTo(view.snp_bottom)
        }
    }
    
    @IBAction func commentTapped(sender: AnyObject) {
        environment.router?.showDiscussionCommentsFromController(self)
    }
    
    // Mark - tableview delegate methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return 5 // TODO return the actual number of responses
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionPostCell.identifier, forIndexPath: indexPath) as! DiscussionPostCell
            // TODO populate with the actual data
            cell.titleLabel.text = "Test Discusstion Title"
            cell.bodyTextLabel.text = "Test body text. Test body text. Test body text. Test body text. Test body text. Test body text. Test body text."
            cell.visibilityLabel.text = "This post is visible to cohort test"
            cell.authorLabel.text = "2 months ago test"
            cell.responseCountLabel.text = "8 responses test"
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionResponseCell.identifier, forIndexPath: indexPath) as! DiscussionResponseCell
            cell.bodyTextLabel.text = "This is a test response. This is a test response. This is a test response. This is a test response. This is a test response. This is a test response. This is a test response. This is a test response. This is a test response. "
            cell.authorLabel.text = "2 days ago test"
            cell.commentButton.setTitle("4 Comments to this response test", forState: .Normal)
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