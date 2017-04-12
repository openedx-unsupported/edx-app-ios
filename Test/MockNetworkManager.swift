//
//  MockNetworkManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//


import XCTest
import edXCore

struct MockSuccessResult<Out> {
    let data : Out
}

class MockNetworkManager: NetworkManager {
    
    fileprivate class Interceptor : NSObject {
        
        // Storing these as Any types is kind of ridiculous, but getting swift to contain a list
        // of values with different type parameters doesn't work. One would think you could wrap it
        // with a protocol and associated type, but that doesn't compile. We should revisit this as Swift improves
        let matcher : Any
        let response : Any
        let delay : TimeInterval
        
        init<Out>(matcher : @escaping (NetworkRequest<Out>) -> Bool, delay : TimeInterval, response : @escaping (NetworkRequest<Out>) -> NetworkResult<Out>) {
            self.matcher = matcher as Any
            self.response = response as Any
            self.delay = delay
        }
    }
    
    fileprivate var interceptors : [Interceptor] = []
    
    let responseCache = MockResponseCache()
    
    init(authorizationHeaderProvider: AuthorizationHeaderProvider? = nil, baseURL: URL = NSURL(string:"http://example.com")! as URL) {
        super.init(authorizationHeaderProvider: authorizationHeaderProvider, baseURL: baseURL, cache: responseCache)
    }
    
    @discardableResult func interceptWhenMatching<Out>(_ matcher: @escaping (NetworkRequest<Out>) -> Bool, afterDelay delay : TimeInterval = 0, withResponse response : @escaping (NetworkRequest<Out>) -> NetworkResult<Out>) -> Removable {
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
    
    /// Returns success with the given value
    @discardableResult func interceptWhenMatching<Out>(_ matcher : @escaping (NetworkRequest<Out>) -> Bool, afterDelay delay : TimeInterval = 0, successResponse : @escaping () -> (Data?, Out)) -> Removable {
        return interceptWhenMatching(matcher, afterDelay: delay, withResponse: {[weak self] request in
            let request = self!.URLRequestWithRequest(request).value!
            let (data, value) = successResponse()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: [:])
            return NetworkResult(request: request, response: response, data: value, baseData: data, error: nil)
        })
    }
    /// Returns failure with the given value
    @discardableResult func interceptWhenMatching<Out>(_ matcher : @escaping ((NetworkRequest<Out>) -> Bool), afterDelay delay : TimeInterval = 0, statusCode : Int = 400, error : NSError = NetworkManager.unknownError) -> Removable {
        return interceptWhenMatching(matcher, afterDelay: delay, withResponse: {[weak self] request in
            let request = self!.URLRequestWithRequest(request).value!
            
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: [:])
            return NetworkResult(request: request, response: response, data: nil, baseData: nil, error: error)
            })
    }
    
    fileprivate func removeInterceptor(_ interceptor : Interceptor) {
        if let index = interceptors.index(of: interceptor) {
            self.interceptors.remove(at: index)
        }
    }
    
    @discardableResult override func taskForRequest<Out>(_ request: NetworkRequest<Out>, handler: @escaping (NetworkResult<Out>) -> Void) -> Removable {
        DispatchQueue.main.async {
            
            for interceptor in self.interceptors {
                if let matcher = interceptor.matcher as? (NetworkRequest<Out>) -> Bool,
                    let response = interceptor.response as? (NetworkRequest<Out>) -> NetworkResult<Out>, matcher(request)
                {
                    let time = DispatchTime.now() + Double(Int64(interceptor.delay * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: time) {
                        handler(response(request))
                    }
                    return
                }
            }
            
            let URLRequest = self.URLRequestWithRequest(request).value!
            handler(NetworkResult(request: URLRequest, response: nil, data: nil, baseData: nil, error: NetworkManager.unknownError))
            
        }
        
        return BlockRemovable {}
    }
    
    func reset() {
        self.responseCache.clear()
        self.interceptors.removeAll()
    }
}

class MockNetworkManagerTests : XCTestCase {
    
    func testInterception() {
        let manager = MockNetworkManager(authorizationHeaderProvider: nil, baseURL: URL(string : "http://example.com")!)
        manager.interceptWhenMatching({ _ in true}, withResponse: { _ -> NetworkResult<String> in
            NetworkResult(request : nil, response : nil, data : "Success", baseData : nil, error : nil)
        })
        
        let expectation = self.expectation(description: "Request sent")
        let request = NetworkRequest(method: HTTPMethod.GET, path: "/test", deserializer: .dataResponse({ _ -> Result<String> in
            XCTFail("Should not get here")
            return .failure(NetworkManager.unknownError)
        }))
        manager.taskForRequest(request) {result in
            XCTAssertEqual(result.data!, "Success")
            expectation.fulfill()
        }
        self.waitForExpectations()
    }
    
    func testNoInterceptorsFails() {
        let manager = MockNetworkManager(authorizationHeaderProvider: nil, baseURL: URL(string : "http://example.com")!)
        
        let expectation = self.expectation(description: "Request sent")
        let request = NetworkRequest(method: HTTPMethod.GET, path: "/test", deserializer: .dataResponse({ _ -> Result<String> in
            XCTFail("Should not get here")
            return .failure(NetworkManager.unknownError)
        }))
        
        manager.taskForRequest(request) {result in
            XCTAssertNotNil(result.error)
            expectation.fulfill()
        }
        self.waitForExpectations()
    }
    
}
