//
//  UITableViewCell+Resizeable.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 02/09/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UITableViewCell {
    
    class func heightForLabelWithAttributedText(attributedText : NSAttributedString, cellWidth width : CGFloat) -> CGFloat {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = attributedText
        let newSize = label.sizeThatFits(CGSizeMake(width, CGFloat.max))
        return newSize.height
    }
    
}