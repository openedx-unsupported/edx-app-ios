//
//  ListCursor.swift
//  edX
//
//  Created by Akiva Leffert on 6/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class ListCursor<A> {
    
    private var index : Int
    private var list : [A]
    
    public init(list : [A], index : Int) {
        self.index = index
        self.list = list
    }
    
    /// Return the previous value if available and decrement the index
    public func prev() -> A? {
        if hasPrev {
            index = index - 1
            return list[index]
        }
        else {
            return nil
        }
    }
    
    /// Return the next value if available and increment the index
    public func next() -> A? {
        if hasNext {
            index = index + 1
            return list[index]
        }
        else {
            return nil
        }
    }
    
    public var hasPrev : Bool {
        return index > 0
    }
    
    public var hasNext : Bool {
        return index + 1 < list.count
    }
    
    public var current : A? {
        if index >= 0 && index < list.count {
            return list[index]
        }
        else {
            return nil
        }
    }
    
    /// Return the previous value if possible without changing the current index
    public func peekPrev() -> A? {
        if hasPrev {
            return list[index]
        }
        else {
            return nil
        }
    }
    
    
    /// Return the next value if possible without changing the current index
    public func peekNext() -> A? {
        if hasNext {
            return list[index]
        }
        else {
            return nil
        }
    }
}