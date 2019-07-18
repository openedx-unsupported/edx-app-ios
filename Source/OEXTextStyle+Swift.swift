//
//  OEXTextStyle+Swift.swift
//  edX
//
//  Created by Michael Katz on 5/17/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class OEXTextStyleWithShadow: OEXTextStyle {
    var shadow: ShadowStyle?

    override var attributes: [String : Any] {
        var attr = super.attributes
        if let shadowStyle = shadow {
            attr[NSAttributedString.Key.shadow.rawValue] = shadowStyle.shadow
        }
        return attr
    }
}

extension Dictionary {
    func attributedKeyDictionary()-> [NSAttributedString.Key: Any] {
        var convertedDict: [NSAttributedString.Key: Any] = [:]
        for (key, value) in self {
            convertedDict[NSAttributedString.Key(rawValue: key as? String ?? "")] = value
        }

        return convertedDict
    }
}
