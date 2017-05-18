//
//  WhatsNewObject.swift
//  edX
//
//  Created by Saeed Bashir on 5/2/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

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
            let message = json["message"].string else {
                return nil
        }
        
        if let image = UIImage(named: imageName) {
            self.image = image
            self.title = title
            self.message = message
        }
        else {
            return nil
        }
    }
}
