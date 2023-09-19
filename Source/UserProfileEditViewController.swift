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
                updateDictionary[key] = newValue as AnyObject
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
                updateDictionary[key] = value as AnyObject? ?? "" as AnyObject
            }
            bio = value
        case .AccountPrivacy:
            setLimitedProfile(newValue: NSString(string: value ?? "").boolValue)
        default: break
            
        }
        
    }
}

class UserProfileEditFooterView: UITableViewHeaderFooterView {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.VisibiltyOff.imageWithFontSize(size: 16).image(with: OEXStyles.shared().neutralXDark())
        return imageView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        let style = OEXMutableTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralXDark())
        style.alignment = .left
        label.attributedText = style.attributedString(withText: Strings.Profile.visibilityOffMessgae(platformName: OEXRouter.shared().environment.config.platformName())).setLineSpacing(4)
        return label
    }()

    private func setupViews() {
        addSubview(imageView)
        addSubview(descriptionLabel)

        imageView.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.width.equalTo(16)
            make.height.equalTo(16)
            make.top.equalTo(descriptionLabel)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(self)
            make.top.equalTo(StandardVerticalMargin * 2)
        }
    }
}

class UserProfileEditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    typealias Environment = OEXAnalyticsProvider & DataManagerProvider & NetworkManagerProvider & OEXStylesProvider
    
    var profile: UserProfile
    let environment: Environment
    var disabledFields = [String]()
    var imagePicker: ProfilePictureTaker?
    var banner: ProfileBanner!
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var footerView: UITableViewHeaderFooterView = {
        if profile.parentalConsent == true {
            return UserProfileEditFooterView()
        }
        else {
            return UITableViewHeaderFooterView()
        }
    }()
    
    
    init(profile: UserProfile, environment: Environment) {
        self.profile = profile
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var fields: [JSONFormBuilder.Field] = []
    
    private let headerHeight: CGFloat = 72
    private let spinner = SpinnerView()
    
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
        bannerWrapper.accessibilityIdentifier = "UserProfileEditViewController:banner-wrapper-view"
        bannerWrapper.addSubview(banner)
        
        banner.snp.makeConstraints { make in
            make.trailing.equalTo(bannerWrapper)
            make.leading.equalTo(bannerWrapper)
            make.bottom.equalTo(bannerWrapper)
            make.top.equalTo(bannerWrapper)
        }
        
        let bottomLine = UIView()
        bottomLine.accessibilityIdentifier = "UserProfileEditViewController:bottom-line-view"
        bottomLine.backgroundColor = OEXStyles.shared().neutralLight()
        bannerWrapper.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.left.equalTo(bannerWrapper)
            make.right.equalTo(bannerWrapper)
            make.height.equalTo(1)
            make.bottom.equalTo(bannerWrapper)
        }
        
        
        return bannerWrapper
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        addSubViews()
        title = Strings.ProfileOptions.UserProfile.title
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        view.backgroundColor = environment.styles.standardBackgroundColor()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableHeaderView = makeHeader()
        tableView.tableFooterView = footerView
        tableView.cellLayoutMarginsFollowReadableWidth = false

        
        if let form = JSONFormBuilder(jsonFile: "profiles") {
            JSONFormBuilder.registerCells(tableView: tableView)
            fields = form.fields ?? []
        }
        addBackBarButtonItem()
        setAccessibilityIdentifiers()
    }

    private func setAccessibilityIdentifiers() {
        view.accessibilityIdentifier = "UserProfileEditViewController:view"
        tableView.accessibilityIdentifier = "UserProfileEditViewController:table-view"
        footerView.accessibilityIdentifier = "UserProfileEditViewController:footer"
        banner.accessibilityIdentifier = "UserProfileEditViewController:banner-view"
        spinner.accessibilityIdentifier = "UserProfileEditViewController:spinner-view"
    }
    
    private func addSubViews() {
        view.addSubview(tableView)
        setConstraints()
    }
    
    private func setConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    
    private func addBackBarButtonItem() {
        let backItem = UIBarButtonItem(image: Icon.ArrowLeft.imageWithFontSize(size: 40), style: .plain, target: nil, action: nil)
        backItem.accessibilityIdentifier = "UserProfileEditViewController:back-item"
        backItem.oex_setAction {[weak self] in
            self?.navigationController?.navigationBar.applyUserProfileNavbarColorScheme()
            self?.navigationController?.popViewController(animated: true)
        }
        navigationItem.leftBarButtonItem = backItem
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewHeight = view.bounds.height
        var footerFrame = footerView.frame
        let footerViewRect = footerView.superview?.convert(footerFrame, to: view) ?? .zero
        footerFrame.size.height = viewHeight - footerViewRect.minY
        footerView.frame = footerFrame
    }
    
    private func updateProfile() {
        if profile.hasUpdates {
            let fieldName = profile.updateDictionary.first!.0
            let field = fields.filter{$0.name == fieldName}[0]
            let fieldDescription = field.title!
            
            view.addSubview(spinner)
            spinner.snp.makeConstraints { make in
                make.center.equalTo(view)
            }
            
            environment.dataManager.userProfileManager.updateCurrentUserProfile(profile: profile) {[weak self] result in
                self?.spinner.removeFromSuperview()
                if let newProf = result.value {
                    self?.profile = newProf
                    self?.reloadViews()
                } else {
                    let message = Strings.Profile.unableToSend(fieldName: fieldDescription)
                    self?.showError(message: message)
                    self?.profile.updateDictionary.removeAll()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenProfileEdit)

        updateProfile()
        reloadViews()
    }
    
    func reloadViews() {
        disableLimitedProfileCells(disabled: profile.sharingLimitedProfile)
        self.tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let field = fields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: field.cellIdentifier, for: indexPath as IndexPath)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
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
            let descriptionStyle = OEXMutableTextStyle(weight: .light, size: .xSmall, color: OEXStyles.shared().primaryXLightColor())
            segmentCell.descriptionLabel.attributedText = descriptionStyle.attributedString(withText: Strings.Profile.ageLimit)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let field = fields[indexPath.row]
        field.takeAction(data: profile, controller: self)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let field = fields[indexPath.row]
        let enabled = !disabledFields.contains(field.name)
        cell.isUserInteractionEnabled = enabled
        cell.backgroundColor = enabled ? UIColor.clear : OEXStyles.shared().neutralXLight()

        enabled ? (cell.accessibilityHint = nil) : (cell.accessibilityHint = Strings.Accessibility.disabledHint)
    }
    
    private func disableLimitedProfileCells(disabled: Bool) {
        banner.changeButton.isEnabled = true
        if disabled {
            disabledFields = [UserProfile.ProfileFields.Country.rawValue,
                UserProfile.ProfileFields.LanguagePreferences.rawValue,
                UserProfile.ProfileFields.Bio.rawValue]
            if profile.parentalConsent ?? false {
                //If the user needs parental consent, they can only share a limited profile, so hide this field and change photo button */
                fields.removeAll(where: { $0.name == UserProfile.ProfileFields.AccountPrivacy.rawValue})
                banner.changeButton.isHidden = true
            }
            footerView.contentView.backgroundColor = OEXStyles.shared().neutralXLight()
        } else {
            footerView.contentView.backgroundColor = UIColor.clear
            disabledFields.removeAll()
        }
    }
  
    //MARK: - Update the error view
    
    private func showError(message: String) {
        UIAlertController().showAlert(withTitle: nil, message: message, onViewController: self)
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
                self.showError(message: Strings.Profile.unableToRemovePhoto)
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
        var data = resizedImage.jpegData(compressionQuality: quality)!
        while data.count > MiB && quality > 0 {
            quality -= 0.1
            data = resizedImage.jpegData(compressionQuality: quality)!
        }
        
        banner.shortProfView.image = image
        let endBlurimate = banner.shortProfView.blurimate()

        let networkRequest = ProfileAPI.uploadProfilePhotoRequest(username: profile.username!, imageData: data as NSData)
        environment.networkManager.taskForRequest(networkRequest) { result in
            let anaylticsSource = picker.sourceType == .camera ? AnaylticsPhotoSource.Camera : AnaylticsPhotoSource.PhotoLibrary
            OEXAnalytics.shared().trackSetProfilePhoto(photoSource: anaylticsSource)
            if let _ = result.error {
                endBlurimate.remove()
                self.showError(message: Strings.Profile.unableToSetPhoto)
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
                self.showError(message: Strings.Profile.unableToGet)
            }
        }
        
    }
}
