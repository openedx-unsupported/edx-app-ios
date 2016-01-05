//
//  UITableView+Layout.swift
//  edX
//
//  Created by Akiva Leffert on 12/23/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension UITableView {
    
    // UITableView doesn't work well with footers using autolayout
    // this forces a recalculation.
    // You should call this from viewDidLayoutSubviews
    func autolayoutFooter() {
        let footer = self.tableFooterView
        let size = footer?.systemLayoutSizeFittingSize(CGSizeMake(self.bounds.width, CGFloat.max)) ?? CGSizeZero
        footer?.frame = CGRect(origin: footer?.frame.origin ?? CGPointZero, size: size)
        // do a little dance so the height gets recalculated
        self.tableFooterView = nil
        self.tableFooterView = footer
    }
    
}