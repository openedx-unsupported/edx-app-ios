//
//  OEXInterface+AppReview.swift
//  edX
//
//  Created by Danial Zahid on 2/16/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

private let OEXSavedAppRating = "OEXSavedAppRating"
private let OEXSavedAppVersionWhenLastRated = "OEXSavedAppVersionWhenLastRated"

extension OEXInterface {
    
    /// Save the rating given through app review
    func saveAppRating(rating: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(rating, forKey: OEXSavedAppRating)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    /// Save the app version when app review is done
    func saveAppVersionWhenLastRated(version: String? = NSBundle.mainBundle().oex_shortVersionString()) {
        NSUserDefaults.standardUserDefaults().setObject(version ?? NSBundle.mainBundle().oex_shortVersionString(), forKey: OEXSavedAppVersionWhenLastRated)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func getSavedAppRating() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey(OEXSavedAppRating)
    }
    
    func getSavedAppVersionWhenLastRated() -> String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(OEXSavedAppVersionWhenLastRated)
    }
}
