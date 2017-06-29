//
//  Dictionary+SafeAccessTests.swift
//  edX
//
//  Created by Kyle McCormick on 7/12/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import XCTest
import edX

class NSMutableDictionaryExtensionTestCase: XCTestCase {
    func testSetObjectOrNil() {
        let dict = NSMutableDictionary()
        
        let key1: String = "test1"
        let obj1: Int? = 1
        dict.setObjectOrNil(obj1, forKey: key1)
        if case let extracted?? = dict[key1] as? Int? {
            XCTAssertEqual(extracted, obj1)
        } else {
            XCTAssertTrue(false)
        }
        
        // Note: It is illegal to add nil values to an NSMutableDictionary, so
        //       when we test setObjectOrNil here, we can be sure it did not
        //       attempt to add the nil value to dictionary if no error is
        //       raised.
        //       Furthermore, when we check dict[key2] == nil, we are checking
        //       that key2 is not in dict.
        let key2: String = "test2"
        let obj2: Int? = nil
        dict.setObjectOrNil(obj2, forKey: key2)
        XCTAssertNil(dict[key2])
    }
    
    func testSetSafeObject() {
        let dict = NSMutableDictionary()
        
        let key: String = "test"
        let obj: Int? = 1
        dict.setSafeObject(obj, forKey: key)
        if case let extracted?? = dict[key] as? Int? {
            XCTAssertEqual(extracted, obj)
        } else {
            XCTAssertTrue(false)
        }
    }
}

class DictionaryExtensionTestCase: XCTestCase {
    
    func testSetObjectOrNil() {
        var dict: [String: Int] = [:]
        
        let key1: String = "test1"
        let obj1: Int? = 1
        dict.setObjectOrNil(obj1, forKey: key1)
        XCTAssertEqual(dict[key1], obj1)
        
        let key2: String = "test2"
        let obj2: Int? = nil
        dict.setObjectOrNil(obj2, forKey: key2)
        XCTAssertFalse(dict.keys.contains(key2))
    }
    
    func testSetSafeObject() {
        var dict: [String: Int] = [:]
        
        let key: String = "test"
        let obj: Int? = 1
        dict.setSafeObject(obj, forKey: key)
        XCTAssertEqual(dict[key], 1)
    }
}
