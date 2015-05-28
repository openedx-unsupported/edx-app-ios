//
//  OEXStyles+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 25/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

extension OEXStyles {
    
    func applyGlobalAppearance() {
        
        if (OEXConfig.sharedConfig().shouldEnableNewCourseNavigation()) {
            //Probably want to set the tintColor of UIWindow but it didn't seem necessary right now
            let textAttrs = [NSForegroundColorAttributeName : navigationItemTintColor()]
            
            UINavigationBar.appearance().barTintColor = navigationBarColor()
            UINavigationBar.appearance().tintColor = navigationItemTintColor()
            UINavigationBar.appearance().translucent = false
            UINavigationBar.appearance().titleTextAttributes = textAttrs
            
            UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        }
        
        

    }
}