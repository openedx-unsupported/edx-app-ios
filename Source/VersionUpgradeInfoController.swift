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
    
    private var _isNewVersionAvailable:Bool = false
    private var _latestVersion:String?
    private var _lastSupportedDateString:String?
    private var postNotification:Bool = false
    
    var isNewVersionAvailable: Bool {
        get { return _isNewVersionAvailable }
    }
    
    var latestVersion:String? {
        get { return _latestVersion }
    }
    
    var lastSupportedDateString: String? {
        get { return _lastSupportedDateString }
    }
    
    private func defaultState() {
        _isNewVersionAvailable = false
        _latestVersion = nil
        _lastSupportedDateString = nil
    }
    
    func populateHeaders(httpResponseHeaders headers: [NSObject : AnyObject]?) {
        
        guard let responseHeaders = headers else {
            if _isNewVersionAvailable {
                // if version upgrade header is showing then hide it
                defaultState()
                postVersionUpgradeNotification()
            }
            
            return
        }
        
        if let latestVersion = responseHeaders[AppLatestVersionKey] as? String {
            
            if _latestVersion == latestVersion {
                postNotification = false
            }
            else {
                postNotification = true
            }
            
            _latestVersion = latestVersion
            _isNewVersionAvailable = true
        }
        else {
            // In case if server stop sending version upgrade info
            if _isNewVersionAvailable {
                defaultState()
                postNotification = true
            }
        }
        
        if let versionLastSupportedDate = responseHeaders[AppVersionLastSupportedDateKey] as? String {
            _lastSupportedDateString = versionLastSupportedDate
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