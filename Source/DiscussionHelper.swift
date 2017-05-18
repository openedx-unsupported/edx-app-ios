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
        
        let endorsedIcon = Icon.Answered.attributedTextWithStyle(style: textStyle, inline : true)
        
        switch thread.type {
        case .Question:
            let endorsedText = textStyle.attributedString(withText: Strings.answer)
            label.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [endorsedIcon,endorsedText])
        case .Discussion:
            let endorsedText = textStyle.attributedString(withText: Strings.endorsed)
            label.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [endorsedIcon,endorsedText])
        }
    }
    
    class func messageForError(error: NSError?) -> String {
        
        if let error = error, error.oex_isNoInternetConnectionError {
            return Strings.networkNotAvailableMessageTrouble
        }
        else {
            return Strings.unknownError
        }
    }
    
    class func showErrorMessage(controller: UIViewController?, error: NSError?) {
        
        let controller = controller ?? UIApplication.shared.keyWindow?.rootViewController
        
        if let error = error, error.oex_isNoInternetConnectionError {
            UIAlertController().showAlert(withTitle: Strings.networkNotAvailableTitle, message: Strings.networkNotAvailableMessageTrouble, onViewController: controller ?? UIViewController())
        }
        else {
            controller?.showOverlay(withMessage: Strings.unknownError)
        }
        
    }
    
    class func styleAuthorProfileImageView(imageView: UIImageView) {
        DispatchQueue.main.async {
            imageView.layer.cornerRadius = imageView.bounds.size.width / 2
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = OEXStyles.shared().primaryBaseColor().cgColor
            imageView.clipsToBounds = true
            imageView.layer.masksToBounds = true
        }
    }
    
    class func profileImage(hasProfileImage: Bool, imageURL: String?) ->RemoteImage {
        let placeholder = UIImage(named: "profilePhotoPlaceholder")
        if let URL = imageURL, hasProfileImage {
            return RemoteImageImpl(url: URL, networkManager: OEXRouter.shared().environment.networkManager, placeholder: placeholder, persist: true)
        }
        else {
            return RemoteImageJustImage(image: placeholder)
        }
    }
    
    class func styleAuthorDetails(author: String?, authorLabel: String?, createdAt: NSDate?, hasProfileImage: Bool, imageURL: String?, authoNameLabel: UILabel, dateLabel: UILabel, authorButton: UIButton, imageView: UIImageView, viewController: UIViewController, router: OEXRouter?) {
        let textStyle = OEXTextStyle(weight:.normal, size:.base, color: OEXStyles.shared().neutralXDark())
        // formate author name
        let highlightStyle = OEXMutableTextStyle(textStyle: textStyle)
        if let _ = author, OEXConfig.shared().profilesEnabled {
            highlightStyle.color = OEXStyles.shared().primaryBaseColor()
            highlightStyle.weight = .bold
        }
        else {
            highlightStyle.color = OEXStyles.shared().neutralXDark()
            highlightStyle.weight = textStyle.weight
        }
        let authorName = highlightStyle.attributedString(withText: author ?? Strings.anonymous.oex_lowercaseStringInCurrentLocale())
        var attributedStrings = [NSAttributedString]()
        attributedStrings.append(authorName)
        if let authorLabel = authorLabel {
            attributedStrings.append(textStyle.attributedString(withText: Strings.parenthesis(text: authorLabel)))
        }
        
        let formattedAuthorName = NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
        authoNameLabel.attributedText = formattedAuthorName
        
        if let createdAt = createdAt {
            dateLabel.attributedText = textStyle.attributedString(withText: createdAt.displayDate)
        }
        
        let profilesEnabled = OEXConfig.shared().profilesEnabled
        authorButton.isEnabled = profilesEnabled
        if let author = author, profilesEnabled {
            authorButton.oex_removeAllActions()
            authorButton.oex_addAction({ [weak viewController] _ in
                
                router?.showProfileForUsername(controller: viewController, username: author , editable: false)
                
                }, for: .touchUpInside)
        }
        else {
            // if post is by anonymous user then disable author button (navigating to user profile)
            authorButton.isEnabled = false
        }
        authorButton.isAccessibilityElement = authorButton.isEnabled
        
        imageView.remoteImage = profileImage(hasProfileImage: hasProfileImage, imageURL: imageURL)
        
    }
}
