//
//  ProfileBanner.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class ProfileBanner: UIView {
    
    let shortProfView: ProfileImageView = ProfileImageView()
    let usernameLabel: UILabel = UILabel()
    let editable: Bool
    let changeCallback: (()->())?
    
    
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
            let changeButton = UIButton()
            addSubview(changeButton)
            
            let titleStyle = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().primaryBaseColor())

            let titleStr = titleStyle.attributedStringWithText("Change")
            let camera = Icon.Camera.attributedTextWithStyle(titleStyle)
            let changeTitle = NSAttributedString.joinInNaturalLayout([camera, titleStr])
            
            changeButton.setAttributedTitle(changeTitle, forState: .Normal)
            changeButton.accessibilityHint = "Upload a new profile picture."
            changeButton.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
            
            changeButton.snp_makeConstraints(closure: { (make) -> Void in
                make.centerY.equalTo(shortProfView)
                make.trailing.equalTo(self.snp_trailingMargin).priorityHigh()
                make.leading.equalTo(usernameLabel).priorityLow()
            })
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
        let usernameStyle = OEXTextStyle(weight : .Normal, size: .XXLarge, color: OEXStyles.sharedStyles().neutralBlackT())
        
        shortProfView.remoteImage = profile.image(networkManager)
        usernameLabel.attributedText = usernameStyle.attributedStringWithText(profile.username)
        
    }
    
}

