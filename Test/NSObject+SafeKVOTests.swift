//
//  KVOListenerTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/4/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
@testable import edX

class ListenableObject : NSObject {
    var backing : String = ""
    
    var value : String {
        get {
            return backing
        }
        set {
            self.willChangeValue(forKey: "value")
            self.backing = newValue
            self.didChangeValue(forKey: "value")
        }
    }
}

class KVOListenerTests: XCTestCase {
    
    func testListening() {
        let observed = ListenableObject()
        let expectation = self.expectation(description: "kvo change is observed")
        let remover = observed.oex_addObserver(observer: self, forKeyPath: "value") { (observer, object, value) -> Void in
            let newValue : String = value as! String
            XCTAssertEqual(newValue, "new")
            expectation.fulfill()
        }
        observed.value = "new"
        waitForExpectations()
        remover.remove()
    }
    
    func testRemoval() {
        let observed = ListenableObject()
        let remover = observed.oex_addObserver(observer: self, forKeyPath: "value") { (observer, object, value) -> Void in
            XCTFail("Already removed")
        }
        remover.remove()
        observed.value = "new"
    }

    
    func testRemovalOnDealloc() {
        let observed = ListenableObject()
        let updated = MutableBox(false)
        
        // ensure our new observer is cleaned up by making a function scope for it
        func scope(_ observed : ListenableObject) {
            let observer = NSObject()
            
            // ensure the observer is actually deallocated
            observer.oex_performAction { () -> Void in
                updated.value = true
            }

            observed.oex_addObserver(observer: observer, forKeyPath: "value") { (observer, object, value) -> Void in
                XCTFail("Already removed")
            }
        }
        
        autoreleasepool {
            scope(observed)
        }
        XCTAssertTrue(updated.value)
        observed.value = "new"
    }

    func testObserverOwnsObserved() {
        let cleared = MutableBox(false)
        func scope() {
            let observed = ListenableObject()
            observed.oex_addObserver(observer: self, forKeyPath: "value") { (observer, object, value) -> Void in }
            observed.oex_performAction { () -> Void in
                cleared.value = true
            }
        }

        autoreleasepool {
            scope()
        }
        XCTAssertFalse(cleared.value)
    }

}
