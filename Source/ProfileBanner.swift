//
//  ProfileBanner.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class IconButton : UIControl {
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let spacing: CGFloat = 10
    
    var enabledAttributedString: NSAttributedString?
    var disabledAttributedString: NSAttributedString?
    
    override var enabled: Bool {
        didSet {
            titleLabel.attributedText = enabled ? enabledAttributedString : disabledAttributedString
            tintColor = enabled ? OEXStyles.sharedStyles().primaryBaseColor() : OEXStyles.sharedStyles().disabledButtonColor()
        }
    }
    
    init() {
        super.init(frame: CGRectZero)
        
        addSubview(imageView)
        addSubview(titleLabel)
        
        imageView.snp_makeConstraints { (make) -> Void in
            make.baseline.equalTo(titleLabel.snp_baseline).offset(2)
        }
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.leading.equalTo(imageView.snp_trailing).offset(spacing)
            make.trailing.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func intrinsicContentSize() -> CGSize {
        let imSize = imageView.intrinsicContentSize()
        let titleSize = titleLabel.intrinsicContentSize()
        let height = max(imSize.height, titleSize.height)
        let width = imSize.width + titleSize.width + spacing
        return CGSize(width: width, height: height)
    }
    
    
    func setIconAndTitle(icon: Icon, title: String) {
        let titleStyle = OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().primaryBaseColor())
        let disabledTitleStyle = OEXMutableTextStyle(textStyle: titleStyle)
        disabledTitleStyle.color = OEXStyles.sharedStyles().disabledButtonColor()
        
        let imageSize = OEXTextStyle.pointSizeForTextSize(titleStyle.size)
        let image = icon.imageWithFontSize(imageSize)
        imageView.image = image
        
        enabledAttributedString = titleStyle.attributedStringWithText(title)
        disabledAttributedString = disabledTitleStyle.attributedStringWithText(title)
        titleLabel.attributedText = enabled ? enabledAttributedString : disabledAttributedString
    }
}

/** Helper Class to display a Profile image and username in a row. Optional change [📷] button. */
class ProfileBanner: UIView {
    
    let shortProfView: ProfileImageView = ProfileImageView()
    let usernameLabel: UILabel = UILabel()
    let editable: Bool
    let changeCallback: (()->())?
    let changeButton = IconButton()

  
    private func setupViews() {
        addSubview(shortProfView)
        addSubview(usernameLabel)
        
        usernameLabel.setContentHuggingPriority(1, forAxis: .Horizontal)
        
        shortProfView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.snp_leadingMargin)
            make.height.equalTo(40)
            make.width.equalTo(shortProfView.snp_height)
            make.centerY.equalTo(self)
        }
        
        usernameLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(shortProfView.snp_trailing).offset(6)
            make.centerY.equalTo(shortProfView)
        }
        
        if editable {
            userInteractionEnabled = true
            addSubview(changeButton)

            changeButton.setIconAndTitle(Icon.Camera, title: Strings.Profile.changePictureButton)
            changeButton.accessibilityHint = Strings.Profile.changePictureAccessibilityHint
            
            changeButton.snp_makeConstraints(closure: { (make) -> Void in
                make.centerY.equalTo(shortProfView)
                make.trailing.equalTo(self.snp_trailingMargin).priorityHigh()
                make.leading.equalTo(usernameLabel).priorityLow()
            })
            
            changeButton.oex_addAction({ [weak self] _ in
                self?.changeCallback?()
            }, forEvents: .TouchUpInside)
        }
      

    }
    
    init(editable: Bool, didChange: (()->())) {
        self.editable = editable
        changeCallback = didChange
        super.init(frame: CGRectZero)
        setupViews()
    }
    
    override init(frame: CGRect) {
        editable = false
        changeCallback = nil
        
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showProfile(profile: UserProfile, networkManager: NetworkManager) {
        let usernameStyle = OEXTextStyle(weight : .Normal, size: .Large, color: OEXStyles.sharedStyles().neutralBlackT())
        
        shortProfView.remoteImage = profile.image(networkManager)
        usernameLabel.attributedText = usernameStyle.attributedStringWithText(profile.username)
    }
}
