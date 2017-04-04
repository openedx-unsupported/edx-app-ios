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
                return OEXStyles.shared().neutralWhiteT()
            case .DarkContent:
                return OEXStyles.shared().neutralBlackT()
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
            usernameLabel.attributedText = usernameStyle.attributedString(withText: usernameLabel.attributedText?.string)
        }
    }
  
    private func setupViews() {
        addSubview(shortProfView)
        addSubview(usernameLabel)
        
        usernameLabel.setContentHuggingPriority(1, for: .horizontal)
        
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
            isUserInteractionEnabled = true
            addSubview(changeButton)

            changeButton.setIconAndTitle(icon: Icon.Camera, title: Strings.Profile.changePictureButton)
            changeButton.accessibilityHint = Strings.Profile.changePictureAccessibilityHint
            
            changeButton.snp_makeConstraints(closure: { (make) -> Void in
                make.centerY.equalTo(shortProfView)
                make.trailing.equalTo(self.snp_trailingMargin).priorityHigh()
                make.leading.equalTo(usernameLabel).priorityLow()
            })
            
            changeButton.oex_addAction({ [weak self] _ in
                self?.changeCallback?()
                }, for: .touchUpInside)
        }
      

    }
    
    init(editable: Bool, didChange: @escaping (()->())) {
        self.editable = editable
        changeCallback = didChange
        super.init(frame: CGRect.zero)
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
        shortProfView.remoteImage = profile.image(networkManager: networkManager)
        usernameLabel.attributedText = usernameStyle.attributedString(withText: profile.username)
    }

    var usernameStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .large, color: style.textColor)
    }
}
