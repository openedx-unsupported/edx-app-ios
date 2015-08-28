//
//  UITableViewCell+Expandable.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 27/08/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UITableViewCell {
    
    static func calculateContentSizeForExpandableItems(items : [ExpandableItem]) -> CGFloat {
        var contentSize : CGFloat = 0.0
        
        for item in items {
            contentSize = contentSize + item.attributedString.heightForAttributedStringWithWidth()
        }
        
        return contentSize
    }
}

struct ExpandableItem {
    let attributedString : NSAttributedString
    let containerWidth : CGFloat
}