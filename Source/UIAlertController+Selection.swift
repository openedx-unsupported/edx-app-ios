//
//  UIAlertController+Selection.swift
//  edX
//
//  Created by Akiva Leffert on 7/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIAlertController {
    static func actionSheetWithItems<A : Equatable>(items : [(title : String, value : A)], currentSelection : A? = nil, action : @escaping (A) -> Void) -> UIAlertController {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for (var title, value) in items {
            if let selection = currentSelection, value == selection {
                // Note that checkmark and space have a neutral text flow direction so this is correct for RTL
                title = "✔︎ " + title
            }
            controller.addAction(
                UIAlertAction(title : title, style: .default) {_ in
                    action(value)
                }
            )
        }
        return controller
    }
}

extension UIAlertController {
    func addCancelAction(handler : @escaping (UIAlertAction) -> Void = {_ in }) {
        self.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler : handler))
    }
}
