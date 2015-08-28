//
//  String+ContentSize.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 27/08/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

//extension String {
//    
//    func heightForTextInContainer(width : CGFloat = UIScreen.mainScreen().bounds.size.width - 16, withFont font : UIFont = UIFont.systemFontOfSize(17)) -> CGFloat {
//        let size = self.sizeWithAttributes([NSFontAttributeName : font])
//        let area  = size.height * size.width;
//        let buffer : CGFloat = 10
//        let heightForLabel = area / width
//        return heightForLabel + buffer
//    }
//}

extension NSAttributedString {
    
    func heightForAttributedStringWithWidth(width : CGFloat = UIScreen.mainScreen().bounds.size.width - 20, buffer : CGFloat = 0) -> CGFloat {
        let size = self.boundingRectWithSize(CGSizeMake(width, CGFloat.max), options: .UsesLineFragmentOrigin | .UsesFontLeading, context: nil)
        return size.height + buffer
    }
    
}
