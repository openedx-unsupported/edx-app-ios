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
    public let value : A
    public init(_ value : A) {
        self.value = value
    }
}

public class MutableBox<A> {
    public var value : A
    public init(_ value : A) {
        self.value = value
    }
}

