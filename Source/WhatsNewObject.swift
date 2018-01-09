//
//  WhatsNewObject.swift
//  edX
//
//  Created by Saeed Bashir on 5/2/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

fileprivate enum SupportPlatforms: String {
    case iOS = "ios"
}

public struct WhatsNew: Equatable {
    // itemID is property designated to uniquely identify all objects. It is used to resolve the cyclic behaviour issue on WhatsNew Screen if Multiple objects have same title and message.
    var itemID = 0
    var image: UIImage
    var title: String
    var message: String
    var isLast = false
    
    public static func == (left: WhatsNew, right: WhatsNew) -> Bool {
        return left.title == right.title && left.message == right.message && left.itemID == right.itemID
    }
}

extension WhatsNew {
    init?(json: JSON) {
        guard let imageName = json["image"].string,
            let title = json["title"].string,
            let message = json["message"].string,
            let platforms = json["platforms"].array else {
                return nil
        }
        
        var isSupportMessage = false
        for platform in platforms {
            if platform.string?.lowercased() == SupportPlatforms.iOS.rawValue {
                isSupportMessage = true
                break
            }
        }
        
        if let image = UIImage(named: imageName), isSupportMessage {
            self.image = image
            self.title = title
            self.message = message
        }
        else {
            return nil
        }
    }
}
