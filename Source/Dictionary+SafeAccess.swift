//
//  Dictionary+SafeAccess.swift
//  edX
//
//  Created by Kyle McCormick on 7/10/17.
//  Copyright (c) 2017 edX. All rights reserved.
//

import Foundation

extension NSMutableDictionary {
    /// Variant of setObject:forKey: that doesn't crash if the object is nil.
    /// Instead, it will just do nothing.
    /// This is for cases where you may or may not have an object.
    /// Contrast with NSMutableDictionary.setSafeObject:forKey:
    @objc public func setObjectOrNil(_ object: Value?, forKey: Key) {
        if let obj = object {
            self[forKey] = obj
        }
    }

    /// Variant of setObject:forKey: that doesn't crash if the object is nil.
    /// Instead, it will assert on DEBUG builds and console log on RELEASE builds
    /// This is for cases where you're expecting to have an object
    /// but you don't want to crash if for some reason you don't.
    /// Contrast with NSMutableDictionary.setObjectOrNil:forKey:
    @objc public func setSafeObject(_ object: Value?, forKey: Key) {
        setObjectOrNil(object, forKey: forKey)
        if object == nil {
            #if DEBUG
                assert(false, "Expecting object for key: \(forKey)");
            #else
                OEXLogError("FOUNDATION", "Expecting object for key: \(forKey)");
            #endif
        }
    }
}

extension Dictionary {
    /// Same as NSMutableDictionary.setObjectOrNil:forKey:, but for
    /// Swift dictionaries
    public mutating func setObjectOrNil(_ object: Value?, forKey: Key) {
        if let obj = object {
            self[forKey] = obj
        }
    }
    
    /// Same as NSMutableDictionary.setSafeObject:forKey:, but for
    /// Swift dictionaries
    public mutating func setSafeObject(_ object: Value?, forKey: Key) {
        setObjectOrNil(object, forKey: forKey)
        if object == nil {
            #if DEBUG
                assert(false, "Expecting object for key: \(forKey)");
            #else
                OEXLogError("FOUNDATION", "Expecting object for key: \(forKey)");
            #endif
        }
    }
}
