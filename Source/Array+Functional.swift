//
//  Array+Functional.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension Array {
    
    init(count : Int, @noescape generator : Int -> Element) {
        self.init()
        for i in 0 ..< count {
            self.append(generator(i))
        }
    }
    
    /// Performs a map, but if any of the items return nil, return nil for the overall result.
    func mapOrFailIfNil<U>(@noescape f : Element -> U?) -> [U]? {
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
    
    /// Performs a map, but skips any items that return nil
    func mapSkippingNils<U>(@noescape f : Element -> U?) -> [U] {
        var result : [U] = []
        for v in self {
            if let t = f(v) {
                result.append(t)
            }
        }
        return result
    }
    
    /// Returns the index of the first object in the array where the given predicate returns true.
    /// Returns nil if no object is found.
    func firstIndexMatching(@noescape predicate : Element -> Bool) -> Int? {
        var i = 0
        for object in self {
            if predicate(object) {
                return i
            }
            i = i + 1
        }
        return nil
    }
    
    func firstObjectMatching(@noescape predicate : Element -> Bool) -> Element? {
        for object in self {
            if predicate(object) {
                return object
            }
        }
        return nil
    }
    
    func withItemIndexes() -> [(value : Element, index : Int)] {
        var result : [(value : Element, index : Int)] = []
        var i = 0
        for value in self {
            let next = (value : value, index : i)
            result.append(next)
            i++
        }
        return result
    }

    // Returns an array with the output of constructor inserted between each element
    // For example [1, 3, 5].interpose({ 2 }) would return [1, 2, 3, 2, 4]
    // constructor is called fresh for each element
    func interpose(@noescape constructor : () -> Element) -> [Element] {
        var result : [Element] = []
        var first = true
        for item in self {
            if !first {
                result.append(constructor())
            }
            result.append(item)
            first = false
        }
        return result
    }
}
