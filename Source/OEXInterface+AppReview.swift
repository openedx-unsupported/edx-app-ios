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
        UserDefaults.standard.set(rating, forKey: OEXSavedAppRating)
        UserDefaults.standard.synchronize()
    }
    
    /// Save the app version when app review is done
    func saveAppVersionWhenLastRated(version: String? = Bundle.main.oex_shortVersionString()) {
        UserDefaults.standard.set(version ?? Bundle.main.oex_shortVersionString(), forKey: OEXSavedAppVersionWhenLastRated)
        UserDefaults.standard.synchronize()
    }
    
    func getSavedAppRating() -> Int {
        return UserDefaults.standard.integer(forKey: OEXSavedAppRating)
    }
    
    func getSavedAppVersionWhenLastRated() -> String? {
        return UserDefaults.standard.string(forKey: OEXSavedAppVersionWhenLastRated)
    }
}
