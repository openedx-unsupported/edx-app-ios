//
//  Utilities.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class Utilities: NSObject {

    class func openUrlInBrowser(url : NSURL!) {
            UIApplication.sharedApplication().openURL(url)
    }
}
