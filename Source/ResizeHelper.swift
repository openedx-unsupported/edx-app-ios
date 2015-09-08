//
//  ResizeHelper.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/09/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
   
func heightForLabelWithAttributedText(attributedText : NSAttributedString, cellWidth width : CGFloat, bufferFactor : CGFloat = 1.1) -> CGFloat {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = attributedText
        let newSize = label.sizeThatFits(CGSizeMake(width, CGFloat.max))
        return newSize.height * bufferFactor
    }
