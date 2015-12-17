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
            return Stream<Paginated<[Int]>>()
        }
        XCTAssertTrue(paginator.hasNext)
    }
    
    func testWrappedPaginatorContinuesLoadable() {
        let paginator = WrappedPaginator<Int> { _ in
            let info = PaginationInfo(totalCount: 100, pageCount: 4)
            return Stream(value: Paginated(pagination: info, value: sampleResult))
        }
        XCTAssertTrue(paginator.hasNext)
        paginator.loadMore()
        
        XCTAssertEqual(paginator.stream.value!, sampleResult)
        XCTAssertTrue(paginator.hasNext)
    }
    
    func testWrappedPaginatorEnds() {
        let paginator = WrappedPaginator<Int> { _ in
            let info = PaginationInfo(totalCount: 100, pageCount: 4)
            return Stream(value: Paginated(pagination: info, value: sampleResult))
        }
        while paginator.hasNext {
            paginator.loadMore()
        }
        XCTAssertEqual(paginator.stream.value!.count, 100)
    }
    
    func testWrappedPaginatorOnlyLoadsWhenInactive() {
        var loadAttempts = 0
        let networkManager = MockNetworkManager()
        let paginator = WrappedPaginator<Int>(networkManager: networkManager) {i in
            let request = NetworkRequest<Paginated<[Int]>>(
                method: .GET,
                path: "fakepath",
                deserializer: ResponseDeserializer.JSONResponse { _ in
                    let info = PaginationInfo(totalCount: 100, pageCount: 20)
                    return Success(Paginated(pagination: info, value: sampleResult))
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
    
    func unwrappedPaginatorEnvironment(pageSize : Int = sampleResult.count) -> (MockNetworkManager, UnwrappedNetworkPaginator<Int>) {
        let networkManager = MockNetworkManager()
        let paginator = UnwrappedNetworkPaginator<Int>(networkManager: networkManager) {_ in
            let request = NetworkRequest<[Int]>(
                method: .GET,
                path: "fakepath",
                query: ["page_size" : JSON(pageSize)],
                deserializer: ResponseDeserializer.JSONResponse { _ in
                    return Success(sampleResult)
                }
            )
            return request
        }
        return (networkManager, paginator)
    }
    
    func testUnwrappedPaginatorStartsLoadable() {
        let (_, paginator) = unwrappedPaginatorEnvironment()
        XCTAssertTrue(paginator.hasNext)
    }
    
    func testUnwrappedPaginatorContinuesLoadable() {
        let (networkManager, paginator) = unwrappedPaginatorEnvironment()
        
        networkManager.interceptWhenMatching({(_ : NetworkRequest<[Int]>) in true}) {
            return (nil, sampleResult)
        }
        
        XCTAssertTrue(paginator.hasNext)
        paginator.loadMore()
        
        waitForStream(paginator.stream)
        XCTAssertEqual(paginator.stream.value!, sampleResult)
        XCTAssertTrue(paginator.hasNext)
    }
    
    func testUnwrappedPaginatorEnds() {
        let (networkManager, paginator) = unwrappedPaginatorEnvironment(sampleResult.count + 1)

        networkManager.interceptWhenMatching({(_ : NetworkRequest<[Int]>) in true}) {
            return (nil, sampleResult)
        }
        
        XCTAssertTrue(paginator.hasNext)
        paginator.loadMore()
        
        waitForStream(paginator.stream)
        XCTAssertFalse(paginator.hasNext)
    }
    
    
    func testUnwrappedPaginatorOnlyLoadsWhenInactive() {
        let (networkManager, paginator) = unwrappedPaginatorEnvironment()
        var loadAttempts = 0
        
        networkManager.interceptWhenMatching({(_ : NetworkRequest<[Int]>) in true}) {
            loadAttempts = loadAttempts + 1
            return (nil, sampleResult)
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
