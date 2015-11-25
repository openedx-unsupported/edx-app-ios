//
//  ShareHelper.swift
//  edX
//
//  Created by Michael Katz on 11/25/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

func shareTextAndALink(text: String, url: NSURL, analyticsCallback:(String -> Void)?) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
    controller.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll]
    controller.completionWithItemsHandler = {activityType, completed, _, error in
        if let type = activityType where completed {
            let analyticsType: String
            switch type {
            case UIActivityTypePostToTwitter:
                analyticsType = "twitter"
            case UIActivityTypePostToFacebook:
                analyticsType = "facebook"
            default:
                analyticsType = "other"
            }
            analyticsCallback?(analyticsType)
        }
    }
    return controller
}