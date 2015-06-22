//
//  MockNetworkManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX

class MockNetworkManager: NetworkManager {
    
    private class Interceptor : NSObject {
        
        // Storing these as Any types is kind of ridiculous, but getting swift to contain a list
        // of values with different type parameters doesn't work. One would think you could wrap it
        // with a protocol and associated type, but that doesn't compile. We should revisit this as Swift improves
        let matcher : Any
        let response : Any
        let delay : NSTimeInterval
        
        init<Out>(matcher : NetworkRequest<Out> -> Bool, delay : NSTimeInterval, response : () -> NetworkResult<Out>) {
            self.matcher = matcher as Any
            self.response = response as Any
            self.delay = delay
        }
    }
    
    private var interceptors : [Interceptor] = []
    
    let responseCache = MockResponseCache()
    
    init(authorizationHeaderProvider: AuthorizationHeaderProvider? = nil, baseURL: NSURL) {
        super.init(authorizationHeaderProvider: authorizationHeaderProvider, baseURL: baseURL, cache: responseCache)
    }
    
    func addMatcher<Out>(matcher: NetworkRequest<Out> -> Bool, delay : NSTimeInterval = 0, response : () -> NetworkResult<Out>) -> Removable {
        let interceptor = Interceptor(
            matcher : matcher,
            delay : delay,
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
    
    override func taskForRequest<Out>(request: NetworkRequest<Out>, handler: NetworkResult<Out> -> Void) -> Removable {
        dispatch_async(dispatch_get_main_queue()) {
            for interceptor in self.interceptors {
                if let matcher = interceptor.matcher as? NetworkRequest<Out> -> Bool,
                    response = interceptor.response as? () -> NetworkResult<Out>
                    where matcher(request)
                {
                    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(interceptor.delay * NSTimeInterval(NSEC_PER_SEC)))
                    dispatch_after(time, dispatch_get_main_queue()) {
                        handler(response())
                    }
                }
            }
        }
        
        return BlockRemovable {}
    }
}

class MockNetworkManagerTests : XCTestCase {
    
    func testInterception() {
        let manager = MockNetworkManager(authorizationHeaderProvider: nil, baseURL: NSURL(string : "http://example.com")!)
        manager.addMatcher({ _ in true}, response: { () -> NetworkResult<String> in
            NetworkResult(request : nil, response : nil, data : "Success", baseData : nil, error : nil)
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
        self.waitForExpectations()
    }
    
}
