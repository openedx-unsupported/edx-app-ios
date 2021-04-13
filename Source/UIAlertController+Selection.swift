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
        for (title, value) in items {
            let alertAction = UIAlertAction(title : title, style: .default) {_ in
                action(value)
            }
            
            if let selection = currentSelection, value == selection {
                alertAction.setValue(true, forKey: "checked")
            }

            controller.addAction(alertAction)
        }
        return controller
    }
}

extension UIAlertController {
    func addCancelAction(handler : @escaping (UIAlertAction) -> Void = {_ in }) {
        addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler : handler))
    }
}
