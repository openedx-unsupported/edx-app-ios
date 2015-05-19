//
//  Array+Functional.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension Array {
    
    /// Performs a map, but if any of the items return nil, return nil for the overall result.
    func mapOrFailIfNil<U>(@noescape f : T -> U?) -> [U]? {
        return reduce([], combine: { (var acc, v) -> [U]? in
            if let x = f(v) {
                acc?.append(x)
                return acc
            }
            else {
                return nil
            }
        })
    }
    
    /// Returns the index of the first object in the array where the given predicate returns true.
    /// Returns nil if no object is found.
    func firstIndexMatching(@noescape predicate : T -> Bool) -> Int? {
        var i = 0
        for object in self {
            if predicate(object) {
                return i
            }
            i = i + 1
        }
        return nil
    }
    
    func firstObjectMatching(@noescape predicate : T -> Bool) -> T? {
        for object in self {
            if predicate(object) {
                return object
            }
        }
        return nil
    }
}