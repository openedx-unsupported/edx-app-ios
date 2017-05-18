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
    private let list : [A]
    
    public init(before : [A], current : A, after : [A]) {
        self.index = before.count
        var list = before
        list.append(current)
        list.append(contentsOf: after)
        self.list = list
    }
    
    // Will fail if current is not in the list
    public init?(list: [A], currentFinder : (A) -> Bool) {
        if let index = list.firstIndexMatching(currentFinder) {
            self.index = index
            self.list = list
        }
        else {
            self.index = 0
            self.list = []
            return nil
        }
    }
    
    public init(cursor : ListCursor<A>) {
        self.index = cursor.index
        self.list = cursor.list
    }
    
    public init?(startOfList list : [A]) {
        if list.count == 0 {
            self.index = 0
            self.list = []
            return nil
        }
        else {
            self.index = 0
            self.list = list
        }
    }
    
    public init?(endOfList list : [A]) {
        if list.count == 0 {
            self.index = 0
            self.list = []
            return nil
        }
        else {
            self.index = list.count - 1
            self.list = list
        }
    }
    
    public func updateCurrentToItemMatching(matcher : (A) -> Bool) {
        if let index = list.firstIndexMatching(matcher) {
            self.index = index
        }
        else {
            assert(false, "Could not find item in cursor")
        }
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
    
    public var current : A {
        assert(index >= 0 && index < list.count, "Invariant violated")
        return list[index]
    }
    
    /// Return the previous value if possible without changing the current index
    public func peekPrev() -> A? {
        if hasPrev {
            return list[index - 1]
        }
        else {
            return nil
        }
    }
    
    
    /// Return the next value if possible without changing the current index
    public func peekNext() -> A? {
        if hasNext {
            return list[index + 1]
        }
        else {
            return nil
        }
    }
    
    public func loopToStartExcludingCurrent( f : (ListCursor<A>, Int) -> Void) {
        while let _ = prev() {
            f(self, self.index)
        }
    }
    
    public func loopToEndExcludingCurrent( f : (ListCursor<A>, Int) -> Void) {
        while let _ = next() {
            f(self, self.index)
        }
    }
    
    /// Loops through all values backward to the beginning, including the current block
    public func loopToStart( f : (ListCursor<A>, Int) -> Void) {
        for i in Array((0 ... self.index).reversed()) {
            self.index = i
            f(self, i)
        }
    }
    
    /// Loops through all values forward to the end, including the current block
    public func loopToEnd( f : (ListCursor<A>, Int) -> Void) {
        for i in self.index ..< self.list.count {
            self.index = i
            f(self, i)
        }
    }
}
