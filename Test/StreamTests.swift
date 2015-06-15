//
//  StreamTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class StreamTests: XCTestCase {
    func testNotify() {
        let sink = Sink<String>()
        let fired = MutableBox(false)
        let message = "hi"
        
        withExtendedLifetime(NSObject()) { (owner : NSObject) -> Void in
            sink.addObserver(owner) {s in
                fired.value = true
                XCTAssertEqual(s, message)
            }
            sink.put(message)
        }
        XCTAssertEqual(sink.value!, message)
        XCTAssertTrue(fired.value)
    }
    
    func testInitialFireDisabled() {
        let sink = Sink<String>()
        let fired = MutableBox(false)
        
        sink.put("something")
        
        withExtendedLifetime(NSObject()) { (owner : NSObject) -> Void in
            sink.addObserver(owner, fireIfValuePresent: false) {_ in
                fired.value = true
            }
        }
        XCTAssertFalse(fired.value)
    }
    
    func testInitialFireEnabled() {
        let sink = Sink<String>()
        let fired = MutableBox(false)
        let message = "hi"
        
        sink.put(message)
        
        withExtendedLifetime(NSObject()) { (owner : NSObject) -> Void in
            sink.addObserver(owner, fireIfValuePresent: true) {
                XCTAssertEqual(message, $0)
                fired.value = true
            }
        }
        XCTAssertTrue(fired.value)
    }

    
    func testAutoRemove() {
        let sink = Sink<String>()
        let fired = MutableBox(false)
        
        func make() {
            autoreleasepool {
                withExtendedLifetime(NSObject()) { (owner : NSObject) -> Void in
                    sink.addObserver(owner) {s in
                        fired.value = true
                    }
                }
            }
        }
        make()
        sink.put("bar")
        XCTAssertFalse(fired.value)
    }
    
    func testManualRemove() {
        let sink = Sink<String>()
        let fired = MutableBox(false)
        
        withExtendedLifetime(NSObject()) { (owner : NSObject) -> Void in
            let removable = sink.addObserver(owner) {s in
                fired.value = true
            }
            removable.remove()
            sink.put("bye")
            XCTAssertFalse(fired.value)
        }
    }

    func testJoinPairs() {
        let sinkA = Sink<String>()
        let sinkB = Sink<Int>()
        let joined = join(sinkA, sinkB)
        let fired = MutableBox(false)
        
        withExtendedLifetime(NSObject()) {(owner : NSObject) -> Void in
            joined.addObserver(owner) {(s, i) in
                XCTAssertEqual(s, "hi")
                XCTAssertEqual(i, 1)
                fired.value = true
            }
            sinkA.put("hi")
            XCTAssertFalse(fired.value)
            
            sinkB.put(1)
            XCTAssertTrue(fired.value)
        }
    }
    
    func testJoinArray() {
        let sinks = [Sink<String>(), Sink<String>(), Sink<String>()]
        let joined = join(sinks)
        let fired = MutableBox(false)
        
        withExtendedLifetime(NSObject()) {(owner : NSObject) -> Void in
            joined.addObserver(owner) {items in
                fired.value = true
                XCTAssertEqual(join(" ", items), "all messages received")
            }
            sinks[0].put("all")
            XCTAssertFalse(fired.value)
            
            sinks[1].put("messages")
            XCTAssertFalse(fired.value)
            
            sinks[2].put("received")
            XCTAssertTrue(fired.value)
        }
    }
    
    func testJoinArrayInitialFire() {
        let sinks = [Sink<String>(), Sink<String>(), Sink<String>()]
        let joined = join(sinks)
        let fired = MutableBox(false)
        
        sinks[0].put("all")
        sinks[1].put("messages")
        sinks[2].put("received")
        
        withExtendedLifetime(NSObject()) {(owner : NSObject) -> Void in
            joined.addObserver(owner) {items in
                fired.value = true
                XCTAssertEqual(join(" ", items), "all messages received")
            }
        }
        XCTAssertTrue(fired.value)
    }
    
    func testSkipFutureErrors() {
        let sink = Sink<Result<String>>()
        let filteredSink = filterErrorsAfterValueFound(sink)
        
        sink.put(Failure())
        XCTAssertNotNil(filteredSink.value?.error)
        
        sink.put(Success("a"))
        XCTAssertEqual(filteredSink.value!.value!, "a")
        
        sink.put(Failure())
        XCTAssertEqual(filteredSink.value!.value!, "a")
        
        sink.put(Success("b"))
        XCTAssertEqual(filteredSink.value!.value!, "b")
    }
    
    func testCancelling() {
        let fired = MutableBox(false)
        let removable = BlockRemovable {
            fired.value = true
        }
        func scope() {
            let sink = CancellingSink<String>(removable: removable)
        }
        scope()
        
        XCTAssertTrue(fired.value)
    }
}
