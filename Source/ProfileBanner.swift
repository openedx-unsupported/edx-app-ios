//
//  ProfileBanner.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

/** Helper Class to display a Profile image and username in a row. Optional change [📷] button. */
class ProfileBanner: UIView {

    enum Style {
        case LightContent
        case DarkContent

        var textColor: UIColor {
            switch(self) {
            case .LightContent:
                return OEXStyles.sharedStyles().neutralWhiteT()
            case .DarkContent:
                return OEXStyles.sharedStyles().neutralBlackT()
            }
        }
    }
    
    let shortProfView: ProfileImageView = ProfileImageView()
    let usernameLabel: UILabel = UILabel()
    let editable: Bool
    let changeCallback: (()->())?
    let changeButton = IconButton()

    var style = Style.LightContent {
        didSet {
            usernameLabel.attributedText = usernameStyle.attributedStringWithText(usernameLabel.attributedText?.string)
        }
    }
  
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
        shortProfView.remoteImage = profile.image(networkManager)
        usernameLabel.attributedText = usernameStyle.attributedStringWithText(profile.username)
    }

    var usernameStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Large, color: style.textColor)
    }
}
