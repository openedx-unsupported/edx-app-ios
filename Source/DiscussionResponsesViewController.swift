//
//  DiscussionResponsesViewController.swift
//  edX
//
//  Created by Lim, Jake on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let GENERAL_PADDING: CGFloat = 8.0

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
    
    init(router: OEXRouter?) {
        self.router = router
    }
}


class DiscussionResponsesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var environment: DiscussionResponsesViewControllerEnvironment!
    private var tableView: UITableView = UITableView()
    private let addResponseButton = UIButton.buttonWithType(.System) as! UIButton
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralBase()
        
        tableView.backgroundColor = UIColor.clearColor()
        
        addResponseButton.backgroundColor = OEXStyles.sharedStyles().neutralDark()

        let createAPostString = OEXLocalizedString("ADD_A_RESPONSE", nil)
        let plainText = createAPostString.textWithIconFont(Icon.Create.textRepresentation)
        let styledText = NSMutableAttributedString(string: plainText)
        styledText.setSizeForText(plainText, textSizes: [createAPostString: 16, Icon.Create.textRepresentation: 12])
        styledText.addAttribute(NSForegroundColorAttributeName, value: OEXStyles.sharedStyles().neutralWhite(), range: NSMakeRange(0, count(plainText)))
        
        addResponseButton.setAttributedTitle(styledText, forState: .Normal)
        addResponseButton.contentVerticalAlignment = .Center
        
        addResponseButton.oex_addAction({ (action : AnyObject!) -> Void in
            environment.router?.showDiscussionNewCommentController(self, isResponse: true)
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