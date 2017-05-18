//
//  TableCellStyle.swift
//  edX
//
//  Created by Akiva Leffert on 10/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

enum TableCellStyle {
    case Normal
    case Highlighted
}

extension UITableViewCell {
    func applyStyle(style : TableCellStyle) {
        switch style {
        case .Normal: self.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        case .Highlighted: self.backgroundColor = OEXStyles.shared().primaryXLightColor()
        }
    }
}
