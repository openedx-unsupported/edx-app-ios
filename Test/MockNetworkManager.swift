//
//  MockNetworkManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX

private class StubTask : NetworkTask {
    func cancel() {
    
    }
}

class MockNetworkManager: NetworkManager {
    
    private class Interceptor : NSObject {
        
        // Storing these as Any types is kind of ridiculous, but getting swift to contain a list
        // of values with different type parameters doesn't work. One would think you could wrap it
        // with a protocol and associated type, but that doesn't compile. We should revisit this as Swift improves
        var matcher : Any
        var response : Any
        
        init<Out>(matcher : NetworkRequest<Out> -> Bool, response : () -> NetworkResult<Out>) {
            self.matcher = matcher as Any
            self.response = response as Any
        }
    }
    
    private var interceptors : [Interceptor] = []
    
    func addMatcher<Out>(matcher: NetworkRequest<Out> -> Bool, response : () -> NetworkResult<Out>) -> OEXRemovable {
        let interceptor = Interceptor(
            matcher : matcher,
            response : response
        )
        interceptors.append(interceptor)
        return BlockRemovable(action: { () -> Void in
            self.removeInterceptor(interceptor)
        })
    }
    
    private func removeInterceptor(interceptor : Interceptor) {
        if let index = find(interceptors, interceptor) {
            self.interceptors.removeAtIndex(index)
        }
    }
    
    override func taskForRequest<Out>(request: NetworkRequest<Out>, handler: NetworkResult<Out> -> Void) -> NetworkTask {
        dispatch_async(dispatch_get_main_queue()) {
            for interceptor in self.interceptors {
                if let matcher = interceptor.matcher as? NetworkRequest<Out> -> Bool, response = interceptor.response as? () -> NetworkResult<Out> {
                    handler(response())
                }
            }
        }
        
        return StubTask()
    }
}

class MockNetworkManagerTests : XCTestCase {
    
    func testInterception() {
        let manager = MockNetworkManager(authorizationHeaderProvider: nil, baseURL: NSURL(string : "http://example.com")!)
        manager.addMatcher({ _ in true}, response: { () -> NetworkResult<String> in
            NetworkResult(request : nil, response : nil, data : "Success", error : nil)
        })
        
        let expectation = expectationWithDescription("Request sent")
        let request = NetworkRequest(method: HTTPMethod.GET, path: "/test", deserializer: { _ -> Result<String> in
            XCTFail("Should not get here")
            return Failure(nil)
        })
        manager.taskForRequest(request) {result in
            XCTAssertEqual(result.data!, "Success")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
}
