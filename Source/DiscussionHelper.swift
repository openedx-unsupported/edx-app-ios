//
//  DiscussionHelper.swift
//  edX
//
//  Created by Saeed Bashir on 2/18/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class DiscussionHelper: NSObject {
    
    class func updateEndorsedTitle(thread: DiscussionThread, lebel: UILabel, textStyle: OEXTextStyle) {
        
        let endorsedIcon = Icon.Answered.attributedTextWithStyle(textStyle, inline : true)
        
        switch thread.type {
        case .Question:
            let endorsedText = textStyle.attributedStringWithText(Strings.answer)
            lebel.attributedText = NSAttributedString.joinInNaturalLayout([endorsedIcon,endorsedText])
        case .Discussion:
            let endorsedText = textStyle.attributedStringWithText(Strings.endorsed)
            lebel.attributedText = NSAttributedString.joinInNaturalLayout([endorsedIcon,endorsedText])
        }
    }
}