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
                XCTAssertEqual((items.value!).joined(separator: " "), "all messages received")
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
                XCTAssertEqual((items.value!).joined(separator: " "), "all messages received")
            }
        }
        XCTAssertTrue(fired.value)
    }
    
    func testJoinEmptyArray() {
        let sinks : [Sink<Void>] = []
        let joined = joinStreams(sinks)
        let fired = MutableBox(false)
        
        let _ = withExtendedLifetime(NSObject(), {owner in
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
        
        sink.send(Success(v: "a"))
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Failure())
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Success(v: "b"))
        XCTAssertEqual(filteredSink.value!, "a")
    }
    
    func testDropFailureAfterSuccessInitialFailure() {
        let sink = Sink<String>()
        let filteredSink = sink.dropFailuresAfterSuccess()
        
        sink.send(Failure())
        
        sink.send(Success(v: "a"))
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Failure())
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Success(v: "b"))
        XCTAssertEqual(filteredSink.value!, "b")
    }
    
    func testDropFailureAfterSuccessInitialSuccess() {
        
        let sink = Sink<String>()
        let filteredSink = sink.dropFailuresAfterSuccess()
        
        sink.send(Success(v: "a"))
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Failure())
        XCTAssertEqual(filteredSink.value!, "a")
        
        sink.send(Success(v: "b"))
        XCTAssertEqual(filteredSink.value!, "b")
    }
    
    func testCancelling() {
        let fired = MutableBox(false)
        let removable = BlockRemovable {
            fired.value = true
        }
        func scope() {
            let _ = Sink<String>().autoCancel(removable)
        }
        scope()
        
        XCTAssertTrue(fired.value)
    }
    
    func testCacheByStreamNoCache() {
        let sink = Sink<String>()
        
        // Cache has no value so it will never fire
        let cache = OEXStream<String>()
        
        let backedStream = sink.cachedByStream(cache)
        sink.send("success")
        XCTAssertEqual(backedStream.value!, "success")
    }
    
    
    func testCacheByStreamCacheFirst() {
        let sink = Sink<String>()
        let cache = Sink<String>()
        
        let backedStream = sink.cachedByStream(cache)
        cache.send("success")
        XCTAssertEqual(backedStream.value!, "success")
        
        sink.send("next")
        XCTAssertEqual(backedStream.value!, "next")
        
        sink.send("after")
        XCTAssertEqual(backedStream.value!, "after")
    }
    
    
    func testCacheByStreamCacheAfter() {
        let sink = Sink<String>()
        let cache = Sink<String>()
        
        let backedStream = sink.cachedByStream(cache)
        sink.send("success")
        XCTAssertEqual(backedStream.value!, "success")
        
        cache.send("next")
        XCTAssertEqual(backedStream.value!, "success")
        
        sink.send("after")
        XCTAssertEqual(backedStream.value!, "after")
        
        cache.close()
        XCTAssertTrue(backedStream.active)
        
        sink.close()
        XCTAssertFalse(backedStream.active)
    }
    
    func testActiveSink() {
        let sink = Sink<String>()
        XCTAssertTrue(sink.active)
        sink.close()
        XCTAssertFalse(sink.active)
    }
    
    func testActiveBacked() {
        let sinks = [Sink<String>(), Sink<String>(), Sink<String>()]
        let backedStream = BackedStream<String>()
        
        XCTAssertFalse(backedStream.active)
        
        for sink in sinks {
            backedStream.backWithStream(sink)
            XCTAssertTrue(backedStream.active)
        }
        
        for sink in sinks[0..<2] {
            sink.close()
            XCTAssertTrue(backedStream.active)
        }
        
        backedStream.removeAllBackings()
        XCTAssertFalse(backedStream.active)
    }
    
    func testRemoveSingleBacking() {
        let presentSink = Sink<String>()
        let removedSink = Sink<String>()
        let backedStream = BackedStream<String>()
        backedStream.addBackingStream(presentSink)
        let remover = backedStream.addBackingStream(removedSink)
        
        removedSink.send("foo")
        XCTAssertEqual(backedStream.value, "foo")

        presentSink.send("bar")
        XCTAssertEqual(backedStream.value, "bar")
        
        remover.remove()
        removedSink.send("foo")
        XCTAssertEqual(backedStream.value, "bar")
    }
    
    func testAccumulateSuccess() {
        let sink = Sink<[String]>()
        let accumulator = accumulate(sink)
        sink.send(["a", "b", "c"])
        XCTAssertEqual(accumulator.value!, ["a", "b", "c"])
        sink.send(["d", "e", "f"])
        XCTAssertEqual(accumulator.value!, ["a", "b", "c", "d", "e", "f"])
    }
    
    func testAccumulateInitialError() {
        let sink = Sink<[String]>()
        let accumulator = accumulate(sink)
        let error = NSError.oex_unknownError()
        sink.send(error)
        XCTAssertEqual(accumulator.error!, error)
    }
    
    func testAccumulateErrorAfterSuccess() {
        let sink = Sink<[Int]>()
        let accumulator = accumulate(sink)
        sink.send([1, 2, 3])
        sink.send(NSError.oex_unknownError())
        XCTAssertEqual(accumulator.value!, [1, 2, 3])
    }
    
    func testDelaySends() {
        let sink = Sink<String>()
        let delayed = sink.delay(0.1)
        sink.close() // Close this dependency so we can directly track the delayed stream's activity
        XCTAssertFalse(delayed.active)
        
        sink.send("first")
        XCTAssertTrue(delayed.active)
        
        // Sleep for .1 seconds to make sure the sends are far enough apart to be listened to
        // separately
        usleep(100000)
        
        sink.send("second")
        waitForStream(delayed) {
            XCTAssertEqual($0.value!, "first")
        }
        // Still have a send queued up so the stream should be active
        XCTAssertTrue(delayed.active)
        waitForStream(delayed, fireIfAlreadyLoaded: false) {
            XCTAssertEqual($0.value!, "second")
        }
        // All the events have fired so the stream should be inactive
        XCTAssertFalse(delayed.active)
    }
}
