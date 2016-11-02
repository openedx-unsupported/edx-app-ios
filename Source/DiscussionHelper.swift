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
    
    class func messageForError(error: NSError?) -> String {
        
        if let error = error where error.oex_isNoInternetConnectionError {
            return Strings.networkNotAvailableMessageTrouble
        }
        else {
            return Strings.unknownError
        }
    }
    
    class func styleAuthorProfileImageView(imageView: UIImageView) {
        dispatch_async(dispatch_get_main_queue(),{
            imageView.layer.cornerRadius = imageView.bounds.size.width / 2
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = OEXStyles.sharedStyles().primaryBaseColor().CGColor
            imageView.clipsToBounds = true
            imageView.layer.masksToBounds = true
        })
    }
    
    class func profileImage(hasProfileImage: Bool, imageURL: String?) ->RemoteImage {
        let placeholder = UIImage(named: "profilePhotoPlaceholder")
        if let URL = imageURL where hasProfileImage {
            return RemoteImageImpl(url: URL, networkManager: OEXRouter.sharedRouter().environment.networkManager, placeholder: placeholder, persist: true)
        }
        else {
            return RemoteImageJustImage(image: placeholder)
        }
    }
    
    class func styleAuthorDetails(author: String?, authorLabel: String?, createdAt: NSDate?, hasProfileImage: Bool, imageURL: String?, authoNameLabel: UILabel, dateLabel: UILabel, authorButton: UIButton, imageView: UIImageView, viewController: UIViewController, router: OEXRouter?) {
        let textStyle = OEXTextStyle(weight:.Normal, size:.Base, color: OEXStyles.sharedStyles().neutralXDark())
        // formate author name
        let highlightStyle = OEXMutableTextStyle(textStyle: textStyle)
        if let _ = author where OEXConfig.sharedConfig().profilesEnabled {
            highlightStyle.color = OEXStyles.sharedStyles().primaryBaseColor()
            highlightStyle.weight = .Bold
        }
        else {
            highlightStyle.color = OEXStyles.sharedStyles().neutralXDark()
            highlightStyle.weight = textStyle.weight
        }
        let authorName = highlightStyle.attributedStringWithText(author ?? Strings.anonymous.oex_lowercaseStringInCurrentLocale())
        var attributedStrings = [NSAttributedString]()
        attributedStrings.append(authorName)
        if let authorLabel = authorLabel {
            attributedStrings.append(textStyle.attributedStringWithText(Strings.parenthesis(text: authorLabel)))
        }
        
        let formattedAuthorName = NSAttributedString.joinInNaturalLayout(attributedStrings)
        authoNameLabel.attributedText = formattedAuthorName
        
        if let createdAt = createdAt {
            dateLabel.attributedText = textStyle.attributedStringWithText(createdAt.displayDate)
        }
        
        let profilesEnabled = OEXConfig.sharedConfig().profilesEnabled
        authorButton.enabled = profilesEnabled
        if let author = author where profilesEnabled {
            authorButton.oex_removeAllActions()
            authorButton.oex_addAction({ [weak viewController] _ in
                
                router?.showProfileForUsername(viewController, username: author ?? Strings.anonymous, editable: false)
                
                }, forEvents: .TouchUpInside)
        }
        else {
            // if post is by anonymous user then disable author button (navigating to user profile)
            authorButton.enabled = false
        }
        
        imageView.remoteImage = profileImage(hasProfileImage, imageURL: imageURL)
        
    }
}
