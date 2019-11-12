//
//  FirrebaseNotificationData.swift
//  edX
//
//  Created by Salman on 08/11/2019.
//  Copyright © 2019 edX. All rights reserved.
//

import UIKit

fileprivate enum DataKeys: String, RawStringExtractable {
    case title = "title"
    case body = "body"
}

class FirrebaseNotificationData: NSObject {

    let title: String?
    let body: String?
    let screenLink: ScreenLink?
    
    init(dictionary:[String:Any]) {
        title = dictionary[DataKeys.title] as? String
        body = dictionary[DataKeys.body] as? String
        screenLink = ScreenLink(dictionary: dictionary)
    }
    
}
