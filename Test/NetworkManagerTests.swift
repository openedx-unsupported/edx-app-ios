//
//  NetworkManagerTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest

import edX

func AssertSuccess<A>(result : Result<A> , file : String = __FILE__, line : UInt = __LINE__, #assertions : A -> Void) {
    switch result {
    case let .Success(r): assertions(r.value)
    case let .Failure(e): XCTFail("Unexpected failure: \(e.localizedDescription)", file : file, line : line)
    }
}

class NetworkManagerTests: XCTestCase {
    class AuthProvider : NSObject, AuthorizationHeaderProvider {
        var authorizationHeaders : [String:String] {
            return ["FakeHeader": "TestValue"]
        }
    }
    
    let authProvider = AuthProvider()
    let baseURL = NSURL(string:"http://example.com")!
    
    func testGetConstruction() {
        let manager = NetworkManager(authorizationHeaderProvider: authProvider, baseURL: baseURL)
        let apiRequest = NetworkRequest(method: HTTPMethod.GET, path: "/something", requiresAuth: true, body: RequestBody.DataBody(data: "test".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, contentType: "edx/content"), query: ["a" : JSON("b"), "c":JSON("d")]) { (response, data) -> Result<Void> in
            XCTFail("Shouldn't send request")
            return Failure(nil)
        }
        
        AssertSuccess(manager.URLRequestWithRequest(apiRequest)) { r in
            XCTAssertEqual(r.URL!.absoluteString!, "http://example.com/something?a=b&c=d")
            XCTAssertEqual(r.allHTTPHeaderFields?["Content-Type" as NSString] as! String, "edx/content")
            XCTAssertEqual(r.allHTTPHeaderFields?["FakeHeader" as NSString] as! String, "TestValue")
            XCTAssertEqual(r.HTTPMethod!, "GET")
        }
    }
    
    func testPostConstruction() {
        let manager = NetworkManager(authorizationHeaderProvider: authProvider, baseURL: baseURL)
        let sampleJSON = JSON([
            "Some field" : true,
            "Some other field" : ["a", "b"]
            ])
        let apiRequest = NetworkRequest(method: HTTPMethod.POST, path: "/something", requiresAuth: true, body: RequestBody.JSONBody(sampleJSON), query: ["a" : JSON("b"), "c":JSON("d")]) { (response, data) -> Result<Void> in
            XCTFail("Shouldn't send request")
            return Failure(nil)
        }
        
        AssertSuccess(manager.URLRequestWithRequest(apiRequest)) { r in
            XCTAssertEqual(r.URL!.absoluteString!, "http://example.com/something?a=b&c=d")
            XCTAssertEqual(r.HTTPMethod!, "POST")
            XCTAssertEqual(r.allHTTPHeaderFields?["Content-Type" as NSString] as! String, "application/json")
            XCTAssertEqual(r.allHTTPHeaderFields?["FakeHeader" as NSString] as! String, "TestValue")
            let foundJSON = JSON(data : r.HTTPBody!)
            XCTAssertEqual(foundJSON, sampleJSON)
        }
    }
}
