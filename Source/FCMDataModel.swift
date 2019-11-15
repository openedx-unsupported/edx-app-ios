//
//  FCMDataModel.swift
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
    let link: PushLink?
    
    init(dictionary:[String:Any]) {
        link = PushLink(dictionary: dictionary)
    }
}

///This link will have information of course and screen type which will be use by deeplink manager to route on particular screen.
class PushLink: DeepLink {
    let title: String?
    let body: String?
    
    override init(dictionary: [String : Any]) {
        title = dictionary[DataKeys.title] as? String
        body = dictionary[DataKeys.body] as? String
        super.init(dictionary: dictionary)
    }
}
