//
//  Box.swift
//  edX
//
//  Created by Akiva Leffert on 5/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

/// Simple container to package arbitrary types
/// for things expecting classes
public class Box<A> {
    let value : A
    init(_ value : A) {
        self.value = value
    }
}
