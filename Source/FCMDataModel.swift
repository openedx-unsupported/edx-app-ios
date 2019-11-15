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

class FCMDataModel: NSObject {

    let title: String?
    let body: String?
    let link: DeepLink?
    
    init(dictionary:[String:Any]) {
        title = dictionary[DataKeys.title] as? String
        body = dictionary[DataKeys.body] as? String
        
        //This link will have information of course and screen type which will be use by deeplink manager to route on particular screen.
        link = DeepLink(dictionary: dictionary)
    }
    
}
