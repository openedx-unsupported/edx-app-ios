//
//  UIAlertController+Selection.swift
//  edX
//
//  Created by Akiva Leffert on 7/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIAlertController {
    static func actionSheetWithItems<A : Equatable>(items : [(title : String, value : A)], currentSelection : A? = nil, action : A -> Void) -> UIAlertController {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        for (var title, value) in items {
            if let selection = currentSelection where value == selection {
                // Note that checkmark and space have a neutral text flow direction so this is correct for RTL
                title = "✔︎ " + title
            }
            controller.addAction(
                UIAlertAction(title : title, style: .Default) {_ in
                    action(value)
                }
            )
        }
        return controller
    }
}

extension UIAlertController {
    func addCancelAction(handler : UIAlertAction -> Void = {_ in }) {
        self.addAction(UIAlertAction(title: OEXLocalizedString("CANCEL", nil), style: .Cancel, handler : handler))
    }
}