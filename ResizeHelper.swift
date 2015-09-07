//
//  ResizeHelper.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/09/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

//This class is majorly for dyanamic bound calculation of views which have resizable content.
//If we plan to add more UI elements, it might be worth it to add a Type enum to handle different views.
class ResizeHelper{
   
    class func heightForLabelWithAttributedText(attributedText : NSAttributedString, cellWidth width : CGFloat, bufferFactor : CGFloat = 1.1) -> CGFloat {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = attributedText
        let newSize = label.sizeThatFits(CGSizeMake(width, CGFloat.max))
        return newSize.height * bufferFactor
    }
}
