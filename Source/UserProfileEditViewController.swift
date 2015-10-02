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
        case .LanguagePreferences:
            return languageCode
        case .Country:
            return countryCode
        case .Bio:
            return bio
        case .LimitedProfile:
            return String(sharingLimitedProfile)
        default:
            return nil
        }
    }
    
    func displayValueForKey(key: String) -> String? {
        guard let field = Fields(rawValue: key) else { return nil }
        
        switch field {
        case .YearOfBirth:
            return birthYear.flatMap{ String($0) }
        case .LanguagePreferences:
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
        case .LanguagePreferences:
            let changed =  value != languageCode
            languageCode = value
            if changed {
                updateDictionary[key] = preferredLanguages ?? NSNull()
            }
        case .Country:
            if value != countryCode {
                updateDictionary[key] = value ?? NSNull()
            }
            countryCode = value
        case .Bio:
            if value != bio {
                updateDictionary[key] = value ?? NSNull()
            }
            bio = value
        case .LimitedProfile:
            fallthrough
//            let newValue = (value! as? NSString).boolValue ?? false
        default: break
            
        }
        
    }
}

class UserProfileEditViewController: UITableViewController {

    struct Environment {
        let networkManager: NetworkManager
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
    
    var fields: [JSONFormBuilder.Field] = []
    
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
        
        title = Strings.Profile.editTitle
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        
        tableView.tableHeaderView = makeHeader()
        tableView.tableFooterView = UIView()
        
        if let form = JSONFormBuilder(jsonFile: "profiles") {
            JSONFormBuilder.registerCells(tableView)
            fields = form.fields!
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
        return fields.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let field = fields[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(field.cellIdentifier, forIndexPath: indexPath)
        (cell as! FormCell).applyData(field, data: profile)
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let field = fields[indexPath.row]
        field.takeAction(profile, controller: self)
    }
    
}
