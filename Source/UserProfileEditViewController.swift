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
        guard let field = ProfileFields(rawValue: key) else { return nil }
        
        switch field {
        case .YearOfBirth:
            return birthYear.flatMap{ String($0) }
        case .LanguagePreferences:
            return languageCode
        case .Country:
            return countryCode
        case .Bio:
            return bio
        case .AccountPrivacy:
            return accountPrivacy?.rawValue
        default:
            return nil
        }
    }
    
    func displayValueForKey(key: String) -> String? {
        guard let field = ProfileFields(rawValue: key) else { return nil }
        
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
        guard let field = ProfileFields(rawValue: key) else { return }
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
        case .AccountPrivacy:
            setLimitedProfile(NSString(string: value!).boolValue)
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
    var disabledFields = [String]()
    
    init(profile: UserProfile, environment: Environment) {
        self.profile = profile
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var fields: [JSONFormBuilder.Field] = []
    
    private let toast = ErrorToastView()
    private let headerHeight: CGFloat = 50
    private let spinner = SpinnerView(size: SpinnerView.Size.Large, color: SpinnerView.Color.Primary)
    
    private func makeHeader() -> UIView {
        let banner = ProfileBanner(editable: true) {}
        banner.shortProfView.borderColor = OEXStyles.sharedStyles().neutralLight()
        banner.backgroundColor = tableView.backgroundColor
        
        let networkManager = environment.networkManager
        banner.showProfile(profile, networkManager: networkManager)
        
        
        let bannerWrapper = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: headerHeight))
        bannerWrapper.addSubview(banner)
        bannerWrapper.addSubview(toast)
        
        toast.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bannerWrapper)
            make.trailing.equalTo(bannerWrapper)
            make.leading.equalTo(bannerWrapper)
            make.height.equalTo(0)
        }
        
        banner.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(bannerWrapper)
            make.leading.equalTo(bannerWrapper)
            make.bottom.equalTo(bannerWrapper)
            make.top.equalTo(toast.snp_bottom)
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
        tableView.tableFooterView = UIView() //get rid of extra lines when the content is shorter than a screen
        
        if let form = JSONFormBuilder(jsonFile: "profiles") {
            JSONFormBuilder.registerCells(tableView)
            fields = form.fields!
        }
    }
    
    private func updateProfile() {
        if profile.hasUpdates {
            let fieldName = profile.updateDictionary.first!.0
            let field = fields.filter{$0.name == fieldName}[0]
            let fieldDescription = field.title!
            
            view.addSubview(spinner)
            spinner.snp_makeConstraints { (make) -> Void in
                make.center.equalTo(view)
            }
            
            environment.networkManager.taskForRequest(ProfileAPI.profileUpdateRequest(profile), handler: { result in
                self.spinner.removeFromSuperview()
                if let newProf = result.data {
                    self.profile = newProf
                    self.reloadViews()
                } else {
                    let message = Strings.Profile.unableToSend(fieldDescription)
                    self.showToast(message)
                }
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        hideToast()
        updateProfile()
        reloadViews()
    }
    
    func reloadViews() {
        disableLimitedProfileCells(profile.sharingLimitedProfile)
        self.tableView.reloadData()
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
        cell.selectionStyle = UITableViewCellSelectionStyle.None

        guard let formCell = cell as? FormCell else { return cell }
        formCell.applyData(field, data: profile)
        
        guard let segmentCell = formCell as? JSONFormBuilder.SegmentCell else { return cell }
        //if it's a segmentCell add the callback directly to the control. When we add other types of controls, this should be made more re-usable
        
        //remove actions before adding so there's not a ton of actions
        segmentCell.typeControl.oex_removeAllActions()
        segmentCell.typeControl.oex_addAction({ [weak self] sender in
            let control = sender as! UISegmentedControl
            let limitedProfile = control.selectedSegmentIndex == 1
            let newValue = String(limitedProfile)
            
            self?.profile.setValue(newValue, key: field.name)
            self?.updateProfile()
            self?.disableLimitedProfileCells(limitedProfile)
            self?.tableView.reloadData()
            }, forEvents: .ValueChanged)
        if let under13 = profile.parentalConsent where under13 == true {
            segmentCell.descriptionLabel.text = Strings.Profile.under13.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let field = fields[indexPath.row]
        field.takeAction(profile, controller: self)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let field = fields[indexPath.row]
        let enabled = !disabledFields.contains(field.name)
        cell.userInteractionEnabled = enabled
        cell.backgroundColor = enabled ? UIColor.clearColor() : OEXStyles.sharedStyles().neutralXLight()
    }
    
    private func disableLimitedProfileCells(disabled: Bool) {
        if disabled {
            disabledFields = [UserProfile.ProfileFields.Country.rawValue,
                UserProfile.ProfileFields.LanguagePreferences.rawValue,
                UserProfile.ProfileFields.Bio.rawValue]
            if profile.parentalConsent ?? false {
                //If the user needs parental consent, they can only share a limited profile, so disable this field as well */
                disabledFields.append(UserProfile.ProfileFields.AccountPrivacy.rawValue)
            }
        } else {
            disabledFields.removeAll()
        }
    }
    
    //MARK: - Update the toast view
    
    private func showToast(message: String) {
        toast.setMessage(message)
        setToastHeight(50)
    }
    
    private func hideToast() {
        setToastHeight(0)
    }
    
    private func setToastHeight(toastHeight: CGFloat) {
        toast.hidden = toastHeight <= 1
        toast.snp_updateConstraints(closure: { (make) -> Void in
            make.height.equalTo(toastHeight)
        })
        var headerFrame = self.tableView.tableHeaderView!.frame
        headerFrame.size.height = headerHeight + toastHeight
        self.tableView.tableHeaderView!.frame = headerFrame
        
        self.tableView.tableHeaderView = self.tableView.tableHeaderView
    }
}

/** Error Toast */
private class ErrorToastView : UIView {
    let errorLabel = UILabel()
    let messageLabel = UILabel()
    
    init() {
        super.init(frame: CGRectZero)
        
        backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        addSubview(errorLabel)
        addSubview(messageLabel)
        
        errorLabel.backgroundColor = OEXStyles.sharedStyles().errorBase()
        let errorStyle = OEXMutableTextStyle(weight: .Light, size: .XXLarge, color: OEXStyles.sharedStyles().neutralWhiteT())
        errorStyle.alignment = .Center
        errorLabel.attributedText = Icon.Warning.attributedTextWithStyle(errorStyle)
        errorLabel.textAlignment = .Center
        
        messageLabel.adjustsFontSizeToFitWidth = true
        
        errorLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(errorLabel.snp_height)
        }
        
        messageLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(errorLabel.snp_trailing).offset(10)
            make.trailing.equalTo(self).offset(-10)
            make.centerY.equalTo(self.snp_centerY)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setMessage(message: String) {
        let messageStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
        messageLabel.attributedText = messageStyle.attributedStringWithText(message)
    }

}