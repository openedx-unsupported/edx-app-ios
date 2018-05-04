//
//  Result+Conveniences.swift
//  edX
//
//  Created by Akiva Leffert on 3/9/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

public func Success<A>(v : A) -> Result<A> {
    return Result.success(v)
}

public func Failure<A>(e : NSError = NSError.oex_unknownError()) -> Result<A> {
    return Result.failure(e)
}

extension Optional {

    /// Converts an optional to an error, using `error` if the `self` is `nil`
    func toResult( error : @autoclosure () -> NSError?) -> Result<Wrapped> {
        if let v = self {
            return Success(v: v)
        }
        else {
            return Failure(e: error() ?? NSError.oex_unknownError())
        }
    }

    func toResult() -> Result<Wrapped> {
        return toResult(NSError.oex_unknownError())
    }
}
