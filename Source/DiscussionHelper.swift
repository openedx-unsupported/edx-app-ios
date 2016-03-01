//
//  DiscussionHelper.swift
//  edX
//
//  Created by Saeed Bashir on 2/18/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class DiscussionHelper: NSObject {
    
    class func updateEndorsedTitle(thread: DiscussionThread, label: UILabel, textStyle: OEXTextStyle) {
        
        let endorsedIcon = Icon.Answered.attributedTextWithStyle(textStyle, inline : true)
        
        switch thread.type {
        case .Question:
            let endorsedText = textStyle.attributedStringWithText(Strings.answer)
            label.attributedText = NSAttributedString.joinInNaturalLayout([endorsedIcon,endorsedText])
        case .Discussion:
            let endorsedText = textStyle.attributedStringWithText(Strings.endorsed)
            label.attributedText = NSAttributedString.joinInNaturalLayout([endorsedIcon,endorsedText])
        }
    }
    
    class func styleAuthorButton(authorButton: UIButton, title: NSAttributedString, author: String?, viewController: UIViewController) {
       
        authorButton.setAttributedTitle(title, forState: .Normal)
        
        let profilesEnabled = OEXConfig.sharedConfig().shouldEnableProfiles()
        authorButton.enabled = profilesEnabled
        
        if profilesEnabled {
            authorButton.oex_removeAllActions()
            authorButton.oex_addAction({ [weak viewController] _ in
                
                // posts by anonymous users don't have author
                guard let author = author else { return }
                
                OEXRouter.sharedRouter().showProfileForUsername(viewController, username: author ?? Strings.anonymous, editable: false)
                }, forEvents: .TouchUpInside)
        }
    }
}