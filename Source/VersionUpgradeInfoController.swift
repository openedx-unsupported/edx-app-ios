//
//  VersionUpgradeInfoController.swift
//  edX
//
//  Created by Saeed Bashir on 5/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

let AppLatestVersionKey = "EDX-APP-LATEST-VERSION"
let AppVersionLastSupportedDateKey = "EDX-APP-VERSION-LAST-SUPPORTED-DATE"
let AppNewVersionAvailableNotification = "AppNewVersionAvailableNotification"

class VersionUpgradeInfoController: NSObject {
    
    static let sharedController = VersionUpgradeInfoController()
    
    private(set) var isNewVersionAvailable:Bool = false
    private(set) var latestVersion:String?
    private(set) var lastSupportedDateString:String?
    private var postNotification:Bool = false
    
    private func defaultState() {
        isNewVersionAvailable = false
        latestVersion = nil
        lastSupportedDateString = nil
    }
    
    func populateFromHeaders(httpResponseHeaders headers: [NSObject : AnyObject]?) {
        
        guard let responseHeaders = headers else {
            if isNewVersionAvailable {
                // if version upgrade header is showing then hide it
                defaultState()
                postVersionUpgradeNotification()
            }
            return
        }
        
        if let appLatestVersion = responseHeaders[AppLatestVersionKey] as? String {
            postNotification = latestVersion != appLatestVersion
            latestVersion = appLatestVersion
            isNewVersionAvailable = true
        }
        else {
            // In case if server stop sending version upgrade info
            if isNewVersionAvailable {
                defaultState()
                postNotification = true
            }
        }
        
        if let versionLastSupportedDate = responseHeaders[AppVersionLastSupportedDateKey] as? String {
            lastSupportedDateString = versionLastSupportedDate
        }
        
        if postNotification {
            postVersionUpgradeNotification()
        }
        
    }
    
    private func postVersionUpgradeNotification() {
        
        dispatch_async(dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotificationName(AppNewVersionAvailableNotification, object: self)
        }
    }
}