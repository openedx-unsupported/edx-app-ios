//
//  XCUIElement+Helpers.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

extension XCUIElement : FeatureInteractor {

    ///Removes any current text in the field before typing in the new value
    /// - Parameter text: the text to enter into the field
    func clearAndEnterText(text: String) -> Void {

        self.tap()

        if let stringValue = self.value as? String {
            let deleteString = stringValue.characters.map { _ in "\u{8}" }.joinWithSeparator("")
            self.typeText(deleteString)
        }

        self.typeText(text)
    }
}