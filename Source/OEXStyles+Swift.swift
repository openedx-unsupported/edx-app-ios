//
//  OEXStyles+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 25/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension OEXStyles {
    
    func applyGlobalAppearance() {
        //Probably want to set the tintColor of UIWindow but it didn't seem necessary right now
        UINavigationBar.appearance().barTintColor = self.primaryAccentColor()
        UINavigationBar.appearance().tintColor = self.standardBackgroundColor()
        UINavigationBar.appearance().translucent = false
    }
}