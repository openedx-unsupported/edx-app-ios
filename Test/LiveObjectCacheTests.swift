//
//  LiveObjectCacheTests.swift
//  edX
//
//  Created by Akiva Leffert on 10/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import edX
import Foundation

class LiveObjectCacheTests : XCTestCase {
    let key = "123"
    
    func testGeneration() {
        let object = NSObject()
        let cache = LiveObjectCache<NSObject>()
        let generator = {
            return object
        }
        let value = cache.objectForKey(key, generator: generator)
        XCTAssertEqual(value, object)
    }
    
    func testCacheHit() {
        let cache = LiveObjectCache<NSObject>()
        let counter = MutableBox<Int>(0)
        let generator: () -> NSObject = {
            counter.value = counter.value + 1
            return NSObject()
        }
        cache.objectForKey(key, generator: generator)
        cache.objectForKey(key, generator: generator)
        cache.objectForKey(key, generator: generator)
        cache.objectForKey(key, generator: generator)
        XCTAssertEqual(counter.value, 1, "Cache should return the original object while object in cache")
    }
    
    func testCacheEmpties() {
        let cache = LiveObjectCache<NSObject>()
        let loaded = MutableBox<Bool>(false)
        func isolation() {
            let object = NSObject()
            cache.objectForKey(key) {
                loaded.value = true
                return object
            }
            NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        }
        let fired = MutableBox<Bool>(false)
        autoreleasepool {
            isolation()
        }
        cache.objectForKey(key) {
            fired.value = true
            return NSObject()
        }
        XCTAssertTrue(loaded.value)
        XCTAssertTrue(fired.value)
    }
    
    func testLiveReferenceSaved() {
        let object = NSObject()
        let cache = LiveObjectCache<NSObject>()
        let counter = MutableBox<Int>(0)
        let generator: () -> NSObject = {
            counter.value = counter.value + 1
            return object
        }
        cache.objectForKey(key, generator: generator)
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        // here the NSCache should be cleared, but since the object is live it should still be in cache
        cache.objectForKey(key, generator: generator)
        XCTAssertEqual(counter.value, 1)

    }
    
    func testEmpty() {
        let object = NSObject()
        let cache = LiveObjectCache<NSObject>()
        let counter = MutableBox<Int>(0)
        let generator: () -> NSObject = {
            counter.value = counter.value + 1
            return object
        }
        cache.objectForKey(key, generator: generator)
        cache.empty()
        cache.objectForKey(key, generator: generator)
        XCTAssertEqual(counter.value, 2)
        
    }
}