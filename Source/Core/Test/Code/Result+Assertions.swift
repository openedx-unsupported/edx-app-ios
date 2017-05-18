//
//  Result+Assertions.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import XCTest

import edXCore

func AssertSuccess<A>(_ result : Result<A> , file : StaticString = #file, line : UInt = #line, assertions : ((A) -> Void)? = nil) {
    switch result {
    case let .success(r): assertions?(r)
    case let .failure(e): XCTFail("Unexpected failure: \(e.localizedDescription)", file : file, line : line)
    }
}

func AssertFailure<A>(_ result : Result<A> , file : StaticString = #file, line : UInt = #line, assertions : ((NSError) -> Void)? = nil) {
    switch result {
    case let .success(r): XCTFail("Unexpected success: \(r)", file : file, line : line)
    case let .failure(e): assertions?(e)
    }
}
