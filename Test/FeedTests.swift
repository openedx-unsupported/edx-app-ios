//
//  FeedTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/26/15.
//  Copyright © 2015 edX. All rights reserved.
//

@testable import edX

class FeedTests : XCTestCase {

    func testMap() {
        var counter = 0
        let feed = Feed<Int> {stream in
            let source = Stream(value:counter)
            stream.backWithStream(source)
            counter = counter + 1
        }
        
        let valueFeed = feed.map { $0.description }
        valueFeed.output.listenOnce(self) {
            XCTAssertEqual($0.value!, "0")
        }
        valueFeed.refresh()
        waitForStream(valueFeed.output)
        
        valueFeed.refresh()
        valueFeed.output.listenOnce(self) {
            XCTAssertEqual($0.value!, "1")
        }
        waitForStream(valueFeed.output)
    }
    
}
