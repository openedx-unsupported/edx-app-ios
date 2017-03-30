//
//  ShareHelper.swift
//  edX
//
//  Created by Michael Katz on 11/25/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

func shareTextAndALink(text: String, url: NSURL, analyticsCallback:((String) -> Void)?) -> UIActivityViewController {
    let items = [text, url] as [Any]
    return controllerWithItems(items: items as [AnyObject], analyticsCallback: analyticsCallback)
}

func shareHashtaggedTextAndALink(textBuilder: @escaping (_ hashtagOrPlatform: String) -> String, url: NSURL, analyticsCallback:((String) -> Void)?) -> UIActivityViewController {
    let items = [PlatformHashTag(textBuilder: textBuilder), url]
    return controllerWithItems(items: items, analyticsCallback: analyticsCallback)
}

private func controllerWithItems(items: [AnyObject], analyticsCallback:((String) -> Void)?) -> UIActivityViewController{
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.excludedActivityTypes = [UIActivityType.assignToContact, UIActivityType.print, UIActivityType.saveToCameraRoll]
    controller.completionWithItemsHandler = {activityType, completed, _, error in
        if let type = activityType, completed {
            let analyticsType: String
            switch type {
            case UIActivityType.postToTwitter:
                analyticsType = "twitter"
            case UIActivityType.postToFacebook:
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
    var config: OEXConfig { return OEXConfig.shared() }
    var platformName : String { return config.platformName() }

    let textBuilder: (_ hashtagOrPlatform: String) -> String

    init(textBuilder: @escaping (_ hashtagOrPlatform: String) -> String) {
        self.textBuilder = textBuilder
        super.init()
    }

    @objc fileprivate func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return textBuilder(platformName)
    }

    //If this is going to Twitter and the hashtag has been defined in the configuration, use it otherwise use the platform name

    @objc fileprivate func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        var item = platformName
        if let hashTag = config.twitterConfiguration?.hashTag, activityType == UIActivityType.postToTwitter {
            item = hashTag
        }
        return textBuilder(item)
    }
}
