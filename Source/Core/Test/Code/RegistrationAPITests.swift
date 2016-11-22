//
//  RegistrationAPITests.swift
//  edX
//
//  Created by Akiva Leffert on 3/21/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest

@testable import edXCore

class RegistrationAPITests: XCTestCase {

    func testRegistrationDeserializationSuccess() {
        let response = NSHTTPURLResponse(URL: NSURL(string:"http://example.com/registration")!, statusCode:200, HTTPVersion:nil, headerFields:nil)!
        let result = RegistrationAPI.registrationDeserializer(response, json: [])
        AssertSuccess(result)
    }

    func testRegistrationDeserializationFailure() {
        let response = NSHTTPURLResponse(URL: NSURL(string:"http://example.com/registration")!, statusCode:400, HTTPVersion:nil, headerFields:nil)!
        let result = RegistrationAPI.registrationDeserializer(response, json: ["username":[["user_message":"some message"]]])
        AssertFailure(result)
        print("error is \(result.error ?? "")")
        let registrationError = result.error as? RegistrationAPIError
        XCTAssertNotNil(registrationError)
        XCTAssertEqual(registrationError!.fieldInfo["username"]?.userMessage, "some message")
    }

    func testRegistrationAPIBuilds() {
        let fields = ["username": "test user", "password": "secret"]
        let request = RegistrationAPI.registrationRequest(fields: fields)
        XCTAssertEqual(request.method, HTTPMethod.POST)
        XCTAssertEqual(request.path, "/user_api/v1/account/registration/")
        switch request.body {
        case let .FormEncoded(foundFields):
            XCTAssertEqual(foundFields, fields)
        default: XCTFail() }
    }
}
