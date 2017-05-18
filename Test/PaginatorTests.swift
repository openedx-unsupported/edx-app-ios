//
//  PaginatorTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest

@testable import edX

let sampleResult = [1, 2, 3, 4]
class PaginatorTests: XCTestCase {
    
    func testWrappedPaginatorStartsLoadable() {
        let paginator = WrappedPaginator { i in
            return OEXStream<Paginated<[Int]>>()
        }
        XCTAssertTrue(paginator.hasNext)
    }
    
    func testWrappedPaginatorContinuesLoadable() {
        let paginator = WrappedPaginator<Int> { _ in
            let info = PaginationInfo(totalCount: 100, pageCount: 4)
            return OEXStream(value: Paginated(pagination: info, value: sampleResult))
        }
        XCTAssertTrue(paginator.hasNext)
        paginator.loadMore()
        
        XCTAssertEqual(paginator.stream.value!, sampleResult)
        XCTAssertTrue(paginator.hasNext)
    }
    
    func testWrappedPaginatorEnds() {
        let paginator = WrappedPaginator<Int> { _ in
            let info = PaginationInfo(totalCount: 100, pageCount: 4)
            return OEXStream(value: Paginated(pagination: info, value: sampleResult))
        }
        while paginator.hasNext {
            paginator.loadMore()
        }
        XCTAssertEqual(paginator.stream.value!.count, 100)
    }
    
    func testWrappedPaginatorPageIncreases() {
        // If we trigger loadMore inside the listener, the current page should already be updated
        
        var lastPage = -1
        let paginator = WrappedPaginator<Int> { page in
            XCTAssertGreaterThan(page, lastPage)
            lastPage = page
            
            let info = PaginationInfo(totalCount: 100, pageCount: 4)
            return OEXStream(value: Paginated(pagination: info, value: sampleResult))
        }
        paginator.stream.listenOnce(self) {[weak paginator] _ in
            paginator?.loadMore()
        }
        paginator.loadMore()
        waitForStream(paginator.stream)
        
        // make sure we actually loaded more than once
        XCTAssertGreaterThan(lastPage, 1)
    }
    
    func testWrappedPaginatorOnlyLoadsWhenInactive() {
        var loadAttempts = 0
        let networkManager = MockNetworkManager()
        let paginator = WrappedPaginator<Int>(networkManager: networkManager) {i in
            let request = NetworkRequest<Paginated<[Int]>>(
                method: .GET,
                path: "fakepath",
                deserializer: ResponseDeserializer.jsonResponse { _ in
                    let info = PaginationInfo(totalCount: 100, pageCount: 20)
                    return Success(v: Paginated(pagination: info, value: sampleResult))
                }
            )
            return request
        }
        networkManager.interceptWhenMatching({(_ : NetworkRequest<Paginated<[Int]>>) in true}) {
            let info = PaginationInfo(totalCount: 100, pageCount: 20)
            loadAttempts = loadAttempts + 1
            return (nil, Paginated(pagination: info, value: sampleResult))
        }
        
        // Try loading a bunch of times
        paginator.loadMore()
        paginator.loadMore()
        paginator.loadMore()
        
        self.waitForStream(paginator.stream)
        
        XCTAssertFalse(paginator.stream.active)
        
        // But we should only actually try to load once since we drop requests while we're loading
        XCTAssertEqual(loadAttempts, 1)
    }
}
