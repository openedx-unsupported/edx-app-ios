//
//  UserProfileEditViewController.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit


extension UserProfile : FormData {
    
    func valueForField(key: String) -> String? {
        guard let field = Fields(rawValue: key) else { return nil }
        
        switch field {
        case .YearOfBirth:
            return birthYear.flatMap{ String($0) }
        case .Language:
            return language
        case .Country:
            return country
        case .Bio:
            return bio
        default:
            return nil
        }
    }
    
    func setValue(value: String?, key: String) {
        guard let field = Fields(rawValue: key) else { return }
        switch field {
        case .YearOfBirth:
            let newValue = value.flatMap { Int($0) }
            if newValue != birthYear {
                updateDictionary[key] = newValue ?? NSNull()
            }
            birthYear = newValue
        default: break
            //nop
        }
    }
}

class UserProfileEditViewController: UITableViewController {

    struct Environment {
        let networkManager: NetworkManager
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
            let descriptionStyle = OEXMutableTextStyle(weight: .Light, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark())
            descriptionStyle.lineBreakMode = .ByWordWrapping
            
            titleLabel.attributedText = titleStyle.attributedStringWithText("edX learners can see my:")
            titleLabel.textAlignment = .Natural
            
            typeControl.insertSegmentWithTitle("Full Profile", atIndex: 0, animated: false)
            typeControl.insertSegmentWithTitle("Limited Profile", atIndex: 0, animated: false)
            typeControl.accessibilityHint = "Change what information is shared with others."
            let selectedAttributes = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralBlackT())
            let unselectedAttributes = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
            typeControl.setTitleTextAttributes(selectedAttributes.attributes, forState: .Selected)
            typeControl.setTitleTextAttributes(unselectedAttributes.attributes, forState: .Normal)
            typeControl.tintColor = OEXStyles.sharedStyles().primaryXLightColor()
            
            descriptionLabel.attributedText = descriptionStyle.attributedStringWithText("A limited profile only shares your username, though you can still choose to add your own profile photo.")
            descriptionLabel.textAlignment = .Natural
            descriptionLabel.numberOfLines = 0
            
            titleLabel.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.top.equalTo(contentView.snp_topMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
            }
            
            typeControl.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(titleLabel.snp_bottom).offset(6)
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
            }
            
            descriptionLabel.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(typeControl.snp_bottom).offset(6)
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
                make.bottom.equalTo(contentView.snp_bottomMargin)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    var profile: UserProfile
    let environment: Environment
    
    init(profile: UserProfile, environment: Environment) {
        self.profile = profile
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var rows = ["Switch"]
    var fields: [JSONFormBuilder.Field?] = [nil]
    
    private func makeHeader() -> UIView {
        let banner = ProfileBanner(editable: true) {}
        banner.shortProfView.borderColor = OEXStyles.sharedStyles().neutralLight()
        banner.backgroundColor = tableView.backgroundColor
        
        let networkManager = environment.networkManager
        banner.showProfile(profile, networkManager: networkManager)
        
        let bannerWrapper = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        bannerWrapper.addSubview(banner)
        banner.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(bannerWrapper)
        }
        
        let bottomLine = UIView()
        bottomLine.backgroundColor = OEXStyles.sharedStyles().neutralDark()
        bannerWrapper.addSubview(bottomLine)
        bottomLine.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(bannerWrapper)
            make.right.equalTo(bannerWrapper)
            make.height.equalTo(1)
            make.bottom.equalTo(bannerWrapper)
        }

        return bannerWrapper
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Edit profile"
        
        tableView.registerClass(SwitchCell.self, forCellReuseIdentifier: "Switch")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
        
        
        tableView.tableHeaderView = makeHeader()
        
        if let form = try? JSONFormBuilder(jsonFile: "profiles") {
            JSONFormBuilder.registerCells(tableView)
            rows.appendContentsOf(form!.fields!.map { $0.identifier! })
            fields.appendContentsOf(form!.fields!.map { Optional($0) })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if profile.hasUpdates {
            tableView.reloadData()
            environment.networkManager.taskForRequest(ProfileAPI.profileUpdateRequest(profile), handler: { result in
                if let newProf = result.data {
                    self.profile = newProf
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(rows[indexPath.row], forIndexPath: indexPath)
        if cell is FormCell {
            let field = fields[indexPath.row]!
            (cell as! FormCell).applyData(field, data: profile)
        }
        cell.selectionStyle = .None
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let field = fields[indexPath.row] {
            field.takeAction(profile, controller: self)
        }
    }
    
}
