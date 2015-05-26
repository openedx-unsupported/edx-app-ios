//
//  Result.swift
//  edX
//
//  Created by Akiva Leffert on 5/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public enum Result<A> {
    case Success(Box<A>)
    case Failure(NSError)    
    
    public func map<B>(f : A -> B) -> Result<B> {
        switch self {
        case Success(let v): return .Success(Box(f(v.value)))
        case Failure(let s): return .Failure(s)
        }
    }
    
    public func flatMap<T>(f : A -> Result<T>) -> Result<T> {
        switch self {
        case Success(let v): return f(v.value)
        case Failure(let s): return .Failure(s)
        }
    }
    
    public func ifSuccess(f : A -> Void) -> Result<A> {
        switch self {
        case Success(let v): f(v.value)
        case Failure(_): break
        }
        return self
    }
    
    public func ifFailure(f : NSError -> Void) -> Result<A> {
        switch self {
        case Success(_): break
        case Failure(let message): f(message)
        }
        return self
    }
    
    public var value : A? {
        switch self {
        case Success(let v): return v.value
        case Failure(_): return nil
        }
    }
    
    public var error : NSError? {
        switch self {
        case Success(_): return nil
        case let Failure(e): return e
        }
    }
}

public func Success<A>(v : A) -> Result<A> {
    return Result.Success(Box(v))
}

public func Failure<A>(e : NSError?) -> Result<A> {
    return Result.Failure(e ?? NSError.oex_unknownError())
}

extension Optional {
    
    /// Converts an optional to an error, using `error` if the `self` is `nil`
    func toResult(@autoclosure error : Void -> NSError?) -> Result<T> {
        if let v = self {
            return Success(v)
        }
        else {
            return Failure(error() ?? NSError.oex_unknownError())
        }
    }
}