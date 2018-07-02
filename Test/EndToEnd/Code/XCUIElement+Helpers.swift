//
//  XCUIElement+Helpers.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

extension XCUIElement {

    ///Removes any current text in the field before typing in the new value
    /// - Parameter text: the text to enter into the field
    func clearAndEnterText(_ text: String) -> Void {

        self.tap()

        if let stringValue = self.value as? String {
            let deleteString = stringValue.map { _ in "\u{8}" }.joined(separator: "")
            if deleteString.count > 0 {
                self.typeText(deleteString)
            }
        }

        self.typeText(text)
    }
    /// Sometimes the first tap doesn't take, possibly due to a timing issue around userInteractionEnabled.
    /// Tap in a loop until it works
    func tapUntilElementExists(_ element : XCUIElement) {
        while(!element.exists) {
            self.tap()
            if(!element.exists) {
                sleep(1)
            }
        }
    }
}
