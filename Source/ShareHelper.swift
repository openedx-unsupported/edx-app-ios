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

func shareHashtaggedTextAndALink(textBuilder: @escaping (_ hashtagOrPlatform: String) -> String, url: NSURL, utmParams:CourseShareUtmParameters, analyticsCallback:((String) -> Void)?) -> UIActivityViewController {
    let items = [PlatformHashTag(textBuilder: textBuilder), CourseShareURL(url: url, utmParams: utmParams)]
    return controllerWithItems(items: items, analyticsCallback: analyticsCallback)
}

func shareHashtaggedTextAndALinka(textBuilder: @escaping (_ hashtagOrPlatform: String) -> String, url: NSURL, utmParams:CourseShareUtmParameters, analyticsCallback:((String) -> Void)?) -> UIActivityViewController {
    
    let completionHandler: (UIActivity.ActivityType?) -> () = { activityType in
      if let type = activityType {
        var analyticsType: String = "other"
        if type == UIActivity.ActivityType.postToFacebook {
            analyticsType = "facebook"
        }
        else if type == UIActivity.ActivityType.postToTwitter {
              analyticsType = "twitter"
        }
            
        else if type == UIActivity.ActivityType.mail {
            analyticsType = "email"
        }
            
        else if type.rawValue == ActivityType.linkedin.rawValue {
            analyticsType = "linkedin"
        }
        analyticsCallback?(analyticsType)
      }
    }
    
    let items = [PlatformHashTag(textBuilder: textBuilder), CourseShareURL(url: url, utmParams: utmParams)]
    return controllerWithItems(items: items, completionHandler: completionHandler)
}

private func controllerWithItems(items: [AnyObject], analyticsCallback:((String) -> Void)?) -> UIActivityViewController{
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print, UIActivity.ActivityType.saveToCameraRoll]
    controller.completionWithItemsHandler = {activityType, completed, _, error in
        if let type = activityType, completed {
            let analyticsType: String
            switch type {
            case UIActivity.ActivityType.postToTwitter:
                analyticsType = "twitter"
            case UIActivity.ActivityType.postToFacebook:
                analyticsType = "facebook"
            default:
                analyticsType = "other"
            }
            analyticsCallback?(analyticsType)
        }
    }
    return controller

}

private func controllerWithItems(items: [AnyObject], completionHandler:((UIActivity.ActivityType) -> Void)?) -> UIActivityViewController{
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print, UIActivity.ActivityType.saveToCameraRoll]
    controller.completionWithItemsHandler = {activityType, completed, _, error in
        if let type = activityType, completed {
            completionHandler?(type)
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
    
    fileprivate func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return textBuilder(platformName)
    }

    //If this is going to Twitter and the hashtag has been defined in the configuration, use it otherwise use the platform name
    fileprivate func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        var item = platformName
        if let hashTag = config.twitterConfiguration?.hashTag, activityType == UIActivity.ActivityType.postToTwitter {
            item = hashTag
        }

        return textBuilder(item)
    }
}

// This class creates new course share url by adding utm parameters with it depending on activity type 
private class CourseShareURL: NSObject, UIActivityItemSource {
    let courseShareURL: NSURL
    let courseShareUtmParams: CourseShareUtmParameters
    
    init(url: NSURL, utmParams:CourseShareUtmParameters) {
        courseShareURL = url
        self.courseShareUtmParams = utmParams
    }
    
    fileprivate func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return courseShareURL
    }
    
    fileprivate func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        
        var shareURL: String = courseShareURL.absoluteString ?? ""
        if activityType == UIActivity.ActivityType.postToFacebook, let utmParams = courseShareUtmParams.facebook {
            shareURL = String(format:"%@?%@",courseShareURL, utmParams)
        }
        else if activityType == UIActivity.ActivityType.postToTwitter, let utmParams = courseShareUtmParams.twitter{
            shareURL = String(format:"%@?%@",courseShareURL, utmParams)
        }
            
        else if activityType == UIActivity.ActivityType.mail, let utmParams = courseShareUtmParams.mail {
            shareURL = String(format:"%@?%@",courseShareURL, utmParams)
        }
            
        else if activityType?.rawValue == ActivityType.linkedin.rawValue, let utmParams = courseShareUtmParams.linkedin {
            shareURL = String(format:"%@?%@",courseShareURL, utmParams)
        }
        
        return NSURL(string: shareURL)
    }
}
