//
//  ShareHelper.swift
//  edX
//
//  Created by Michael Katz on 11/25/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

func shareTextAndALink(text: String, url: NSURL, analyticsCallback:(String -> Void)?) -> UIActivityViewController {
    let items = [text, url]
    return controllerWithItems(items, analyticsCallback: analyticsCallback)
}

func shareHashtaggedTextAndALink(textBuilder: (hashtagOrPlatform: String) -> String, url: NSURL, analyticsCallback:(String -> Void)?) -> UIActivityViewController {
    let items = [PlatformHashTag(textBuilder: textBuilder), url]
    return controllerWithItems(items, analyticsCallback: analyticsCallback)
}

private func controllerWithItems(items: [AnyObject], analyticsCallback:(String -> Void)?) -> UIActivityViewController{
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
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


private class PlatformHashTag: NSObject, UIActivityItemSource {
    var config: OEXConfig { return OEXConfig.sharedConfig() }
    var platformName : String { return config.platformName() }

    let textBuilder: (hashtagOrPlatform: String) -> String

    init(textBuilder: (hashtagOrPlatform: String) -> String) {
        self.textBuilder = textBuilder
        super.init()
    }

    @objc private func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return textBuilder(hashtagOrPlatform: platformName)
    }

    //If this is going to Twitter and the hashtag has been defined in the configuration, use it otherwise use the platform name

    @objc private func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        var item = platformName
        if let hashTag = config.twitterConfiguration?.hashTag where activityType == UIActivityTypePostToTwitter {
            item = hashTag
        }
        return textBuilder(hashtagOrPlatform: item)
    }
}