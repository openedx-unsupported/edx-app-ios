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
    var image: UIImage
    var title: String
    var message: String
    var isLast = false
    
    public static func == (left: WhatsNew, right: WhatsNew) -> Bool {
        return left.title == right.title && left.message == right.message
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
        
        if let image = UIImage(named: imageName), isSupportMessage == true {
            self.image = image
            self.title = title
            self.message = message
        }
        else {
            return nil
        }
    }
}
