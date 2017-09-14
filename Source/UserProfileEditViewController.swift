//
//  UserProfileEditViewController.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

let MiB = 1_048_576

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
                updateDictionary[key] = newValue as AnyObject?
            }
            birthYear = newValue
        case .LanguagePreferences:
            let changed =  value != languageCode
            languageCode = value
            if changed {
                updateDictionary[key] = preferredLanguages as AnyObject
            }
        case .Country:
            if value != countryCode {
                updateDictionary[key] = value as AnyObject
            }
            countryCode = value
        case .Bio:
            if value != bio {
                updateDictionary[key] = value as AnyObject 
            }
            bio = value
        case .AccountPrivacy:
            setLimitedProfile(newValue: NSString(string: value!).boolValue)
        default: break
            
        }
        
    }
}

class UserProfileEditViewController: UITableViewController {
    
    typealias Environment = OEXAnalyticsProvider & DataManagerProvider & NetworkManagerProvider
    
    var profile: UserProfile
    let environment: Environment
    var disabledFields = [String]()
    var imagePicker: ProfilePictureTaker?
    var banner: ProfileBanner!
    let footer = UIView()
    
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
    private let headerHeight: CGFloat = 72
    private let spinner = SpinnerView(size: SpinnerView.Size.Large, color: SpinnerView.Color.Primary)
    
    private func makeHeader() -> UIView {
        banner = ProfileBanner(editable: true) { [weak self] in
            self?.imagePicker = ProfilePictureTaker(delegate: self!)
            self?.imagePicker?.start(alreadyHasImage: self!.profile.hasProfileImage)
        }
        banner.style = .DarkContent
        banner.shortProfView.borderColor = OEXStyles.shared().neutralLight()
        banner.backgroundColor = tableView.backgroundColor
        
        let networkManager = environment.networkManager
        banner.showProfile(profile: profile, networkManager: networkManager)
        
        
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
        bottomLine.backgroundColor = OEXStyles.shared().neutralLight()
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
        navigationItem.backBarButtonItem?.title = " "
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        
        tableView.tableHeaderView = makeHeader()
        tableView.tableFooterView = footer //get rid of extra lines when the content is shorter than a screen
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        if let form = JSONFormBuilder(jsonFile: "profiles") {
            JSONFormBuilder.registerCells(tableView: tableView)
            fields = form.fields!
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewHeight = view.bounds.height
        var footerFrame = footer.frame
        let footerViewRect = footer.superview!.convert(footerFrame, to: view)
        footerFrame.size.height = viewHeight - footerViewRect.minY
        footer.frame = footerFrame
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
            
            environment.dataManager.userProfileManager.updateCurrentUserProfile(profile: profile) {[weak self] result in
                self?.spinner.removeFromSuperview()
                if let newProf = result.value {
                    self?.profile = newProf
                    self?.reloadViews()
                } else {
                    let message = Strings.Profile.unableToSend(fieldName: fieldDescription)
                    self?.showToast(message: message)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenProfileEdit)

        hideToast()
        updateProfile()
        reloadViews()
    }
    
    func reloadViews() {
        disableLimitedProfileCells(disabled: profile.sharingLimitedProfile)
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fields.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let field = fields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: field.cellIdentifier, for: indexPath as IndexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.applyStandardSeparatorInsets()

        guard let formCell = cell as? FormCell else { return cell }
        formCell.applyData(field: field, data: profile)
        
        guard let segmentCell = formCell as? JSONFormBuilder.SegmentCell else { return cell }
        //if it's a segmentCell add the callback directly to the control. When we add other types of controls, this should be made more re-usable
        
        //remove actions before adding so there's not a ton of actions
        segmentCell.typeControl.oex_removeAllActions()
        segmentCell.typeControl.oex_addAction({ [weak self] sender in
            let control = sender as! UISegmentedControl
            let limitedProfile = control.selectedSegmentIndex == 1
            let newValue = String(limitedProfile)
            
            self?.profile.setValue(value: newValue, key: field.name)
            self?.updateProfile()
            self?.disableLimitedProfileCells(disabled: limitedProfile)
            self?.tableView.reloadData()
            }, for: .valueChanged)
        if let under13 = profile.parentalConsent, under13 == true {
            let descriptionStyle = OEXMutableTextStyle(weight: .light, size: .xSmall, color: OEXStyles.shared().neutralDark())
            segmentCell.descriptionLabel.attributedText = descriptionStyle.attributedString(withText: Strings.Profile.ageLimit)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let field = fields[indexPath.row]
        field.takeAction(data: profile, controller: self)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let field = fields[indexPath.row]
        let enabled = !disabledFields.contains(field.name)
        cell.isUserInteractionEnabled = enabled
        cell.backgroundColor = enabled ? UIColor.clear : OEXStyles.shared().neutralXLight()
    }
    
    private func disableLimitedProfileCells(disabled: Bool) {
        banner.changeButton.isEnabled = true
        if disabled {
            disabledFields = [UserProfile.ProfileFields.Country.rawValue,
                UserProfile.ProfileFields.LanguagePreferences.rawValue,
                UserProfile.ProfileFields.Bio.rawValue]
            if profile.parentalConsent ?? false {
                //If the user needs parental consent, they can only share a limited profile, so disable this field as well */
                disabledFields.append(UserProfile.ProfileFields.AccountPrivacy.rawValue)
                banner.changeButton.isEnabled = false 
            }
            footer.backgroundColor = OEXStyles.shared().neutralXLight()
        } else {
            footer.backgroundColor = UIColor.clear
            disabledFields.removeAll()
        }
    }
  
    //MARK: - Update the toast view
    
    public func showToast(message: String) {
        toast.setMessage(message: message)
        setToastHeight(toastHeight: 50)
    }
    
    private func hideToast() {
        setToastHeight(toastHeight: 0)
    }
    
    private func setToastHeight(toastHeight: CGFloat) {
        toast.isHidden = toastHeight <= 1
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
        super.init(frame: CGRect.zero)
        
        backgroundColor = OEXStyles.shared().neutralXLight()
        
        addSubview(errorLabel)
        addSubview(messageLabel)
        
        errorLabel.backgroundColor = OEXStyles.shared().errorBase()
        let errorStyle = OEXMutableTextStyle(weight: .light, size: .xxLarge, color: OEXStyles.shared().neutralWhiteT())
        errorStyle.alignment = .center
        errorLabel.attributedText = Icon.Warning.attributedTextWithStyle(style: errorStyle)
        errorLabel.textAlignment = .center
        
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
        let messageStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralBlackT())
        messageLabel.attributedText = messageStyle.attributedString(withText: message)
    }

}

extension UserProfileEditViewController : ProfilePictureTakerDelegate {

    func showImagePickerController(picker: UIImagePickerController) {
        self.present(picker, animated: true, completion: nil)
    }
    
    func showChooserAlert(alert: UIAlertController) {
        alert.configurePresentationController(withSourceView: banner.changeButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    func deleteImage() {
        let endBlurimate = banner.shortProfView.blurimate()
        
        let networkRequest = ProfileAPI.deleteProfilePhotoRequest(username: profile.username!)
        environment.networkManager.taskForRequest(networkRequest) { result in
            if let _ = result.error {
                endBlurimate.remove()
                self.showToast(message: Strings.Profile.unableToRemovePhoto)
            } else {
                //Was sucessful upload
                self.reloadProfileFromImageChange(completionRemovable: endBlurimate)
            }
        }
    }
    
    func imagePicked(image: UIImage, picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
        
        let resizedImage = image.resizedTo(size: CGSize(width: 500, height: 500))
        
        var quality: CGFloat = 1.0
        var data = UIImageJPEGRepresentation(resizedImage, quality)!
        while data.count > MiB && quality > 0 {
            quality -= 0.1
            data = UIImageJPEGRepresentation(resizedImage, quality)!
        }
        
        banner.shortProfView.image = image
        let endBlurimate = banner.shortProfView.blurimate()

        let networkRequest = ProfileAPI.uploadProfilePhotoRequest(username: profile.username!, imageData: data as NSData)
        environment.networkManager.taskForRequest(networkRequest) { result in
            let anaylticsSource = picker.sourceType == .camera ? AnaylticsPhotoSource.Camera : AnaylticsPhotoSource.PhotoLibrary
            OEXAnalytics.shared().trackSetProfilePhoto(photoSource: anaylticsSource)
            if let _ = result.error {
                endBlurimate.remove()
                self.showToast(message: Strings.Profile.unableToSetPhoto)
            } else {
                //Was successful delete
                self.reloadProfileFromImageChange(completionRemovable: endBlurimate)
            }
        }
    }
    
    func cancelPicker(picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }

    private func reloadProfileFromImageChange(completionRemovable: Removable) {
        let feed = self.environment.dataManager.userProfileManager.feedForCurrentUser()
        feed.refresh()
        feed.output.listenOnce(self, fireIfAlreadyLoaded: false) { result in
            completionRemovable.remove()
            if let newProf = result.value {
                self.profile = newProf
                self.reloadViews()
                self.banner.showProfile(profile: newProf, networkManager: self.environment.networkManager)
            } else {
                self.showToast(message: Strings.Profile.unableToGet)
            }
        }
        
    }
}
