//
//  UserProfileEditViewController.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class UserProfileEditViewController: UITableViewController {

    private class BannerCell : UITableViewCell {
        let banner: ProfileBanner
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            banner = ProfileBanner(editable: true) {}

            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            contentView.addSubview(banner)
            
            banner.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(contentView.snp_topMargin)
                make.bottom.equalTo(contentView.snp_bottomMargin)
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
            }
            banner.shortProfView.borderColor = OEXStyles.sharedStyles().primaryDarkColor()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    private class SwitchCell: UITableViewCell {
        let titleLabel = UILabel()
        let descriptionLabel = UILabel()
        let typeControl = UISegmentedControl()
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            contentView.addSubview(titleLabel)
            contentView.addSubview(typeControl)
            contentView.addSubview(descriptionLabel)
            
            let titleStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
            //TODO: title styles
            let descriptionStyle = OEXTextStyle(weight: .Light, size: .Small, color: OEXStyles.sharedStyles().neutralLight())
            
            titleLabel.attributedText = titleStyle.attributedStringWithText("edX learners can see my:")
            titleLabel.textAlignment = .Natural
            
            typeControl.insertSegmentWithTitle("Full Profile", atIndex: 0, animated: false)
            typeControl.insertSegmentWithTitle("Limited Profile", atIndex: 0, animated: false)
            typeControl.accessibilityHint = "Change what information is shared with others."
            
            descriptionLabel.attributedText = descriptionStyle.attributedStringWithText("A limited profile only shares your username, though you can still choose to add your own profile photo.")
            descriptionLabel.textAlignment = .Natural
            descriptionLabel.numberOfLines = 0
            
            titleLabel.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.top.equalTo(contentView.snp_topMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
            }
            
            typeControl.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(titleLabel.snp_bottom)
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
            }
            
            descriptionLabel.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(typeControl.snp_bottom)
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
                make.bottom.equalTo(contentView.snp_bottomMargin)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    let rows = ["Banner", "Switch"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(BannerCell.self, forCellReuseIdentifier: "Banner")
        tableView.registerClass(SwitchCell.self, forCellReuseIdentifier: "Switch")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
        
        let form = try? JSONFormBuilder(jsonFile: "profiles")
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(rows[indexPath.row], forIndexPath: indexPath)
        return cell
    }
    
    
}
