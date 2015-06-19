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
            sink.listen(owner) {s in
                fired.value = true
                XCTAssertEqual(s.value!, message)
            }
            sink.send(message)
        }
        XCTAssertEqual(sink.value!, message)
        XCTAssertTrue(fired.value)
    }
    
    func testInitialFireDisabled() {
        let sink = Sink<String>()
        let fired = MutableBox(false)
        
        sink.send("something")
        
        withExtendedLifetime(NSObject()) { (owner : NSObject) -> Void in
            sink.listen(owner, fireIfAlreadyLoaded: false) {_ in
                fired.value = true
            }
        }
        XCTAssertFalse(fired.value)
    }
    
    func testInitialFireEnabled() {
        let sink = Sink<String>()
        let fired = MutableBox(false)
        let message = "hi"
        
        sink.send(message)
        
        withExtendedLifetime(NSObject()) { (owner : NSObject) -> Void in
            sink.listen(owner) {
                XCTAssertEqual(message, $0.value!)
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
                    sink.listen(owner) {s in
                        fired.value = true
                    }
                }
            }
        }
        make()
        sink.send("bar")
        XCTAssertFalse(fired.value)
    }
    
    func testManualRemove() {
        let sink = Sink<String>()
        let fired = MutableBox(false)
        
        withExtendedLifetime(NSObject()) { (owner : NSObject) -> Void in
            let removable = sink.listen(owner) {s in
                fired.value = true
            }
            removable.remove()
            sink.send("bye")
            XCTAssertFalse(fired.value)
        }
    }

    func testJoinPairs() {
        let sinkA = Sink<String>()
        let sinkB = Sink<Int>()
        let joined = joinStreams(sinkA, sinkB)
        let fired = MutableBox(false)
        
        withExtendedLifetime(NSObject()) {(owner : NSObject) -> Void in
            joined.listen(owner) {result in
                XCTAssertEqual(result.value!.0, "hi")
                XCTAssertEqual(result.value!.1, 1)
                fired.value = true
            }
            sinkA.send("hi")
            XCTAssertFalse(fired.value)
            
            sinkB.send(1)
            XCTAssertTrue(fired.value)
        }
    }
    
    func testJoinArray() {
        let sinks = [Sink<String>(), Sink<String>(), Sink<String>()]
        let joined = joinStreams(sinks)
        let fired = MutableBox(false)
        
        withExtendedLifetime(NSObject()) {(owner : NSObject) -> Void in
            joined.listen(owner) {items in
                fired.value = true
                XCTAssertEqual(" ".join(items.value!), "all messages received")
            }
            sinks[0].send("all")
            XCTAssertFalse(fired.value)
            
            sinks[1].send("messages")
            XCTAssertFalse(fired.value)
            
            sinks[2].send("received")
            XCTAssertTrue(fired.value)
        }
    }
    
    func testJoinArrayInitialFire() {
        let sinks = [Sink<String>(), Sink<String>(), Sink<String>()]
        let joined = joinStreams(sinks)
        let fired = MutableBox(false)
        
        sinks[0].send("all")
        sinks[1].send("messages")
        sinks[2].send("received")
        
        withExtendedLifetime(NSObject()) {(owner : NSObject) -> Void in
            joined.listen(owner) {items in
                fired.value = true
                XCTAssertEqual(" ".join(items.value!), "all messages received")
            }
        }
        XCTAssertTrue(fired.value)
    }
    
    func testJoinEmptyArray() {
        let sinks : [Sink<Void>] = []
        let joined = joinStreams(sinks)
        let fired = MutableBox(false)
        
        withExtendedLifetime(NSObject(), {owner in
            joined.listen(owner) { items in
                fired.value = true
            }
        })
        XCTAssertTrue(fired.value)
    }
    
    func testFirstSuccess() {
        let sink = Sink<String>()
        let filteredSink = sink.firstSuccess()
        
        sink.send(Failure())
        XCTAssertNotNil(filteredSink.error)
        
        sink.send(Success("a"))
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Failure())
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Success("b"))
        XCTAssertEqual(filteredSink.value!, "a")
    }
    
    func testDropFailureAfterSuccessInitialFailure() {
        let sink = Sink<String>()
        let filteredSink = sink.dropFailuresAfterSuccess()
        
        sink.send(Failure())
        
        sink.send(Success("a"))
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Failure())
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Success("b"))
        XCTAssertEqual(filteredSink.value!, "b")
    }
    
    func testDropFailureAfterSuccessInitialSuccess() {
        
        let sink = Sink<String>()
        let filteredSink = sink.dropFailuresAfterSuccess()
        
        sink.send(Success("a"))
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Failure())
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Success("b"))
        XCTAssertEqual(filteredSink.value!, "b")
    }
    
    func testCancelling() {
        let fired = MutableBox(false)
        let removable = BlockRemovable {
            fired.value = true
        }
        func scope() {
            let sink = Sink<String>().autoCancel(removable)
        }
        scope()
        
        XCTAssertTrue(fired.value)
    }
}
