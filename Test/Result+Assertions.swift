//
//  Result+Assertions.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edX

func AssertSuccess<A>(result : Result<A> , file : String = __FILE__, line : UInt = __LINE__, assertions : (A -> Void)? = nil) {
    switch result {
    case let .Success(r): assertions?(r)
    case let .Failure(e): XCTFail("Unexpected failure: \(e.localizedDescription)", file : file, line : line)
    }
}

func AssertFailure<A>(result : Result<A> , file : String = __FILE__, line : UInt = __LINE__, assertions : (NSError -> Void)? = nil) {
    switch result {
    case let .Success(r): XCTFail("Unexpected success: \(r)", file : file, line : line)
    case let .Failure(e): assertions?(e)
    }
}
