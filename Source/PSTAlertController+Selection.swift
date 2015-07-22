//
//  PSTAlertController+Selection.swift
//  edX
//
//  Created by Akiva Leffert on 7/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

func actionSheetWithItems<A : Equatable>(items : [(title : String, value : A)], currentSelection : A? = nil, action : A -> Void) -> PSTAlertController {
    let controller = PSTAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    for (var title, value) in items {
        if let selection = currentSelection where value == selection {
            // Note that checkmark and space have a neutral text flow direction so this is correct for RTL
            title = "✔︎ " + title
        }
        controller.addAction(
            PSTAlertAction(title : title) {_ in
                action(value)
            }
        )
    }
    return controller
}