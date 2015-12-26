//
//  Result.swift
//  edX
//
//  Created by Akiva Leffert on 5/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public enum Result<A> {
    case Success(A)
    case Failure(NSError)    
    
    public func map<B>(f : A -> B) -> Result<B> {
        switch self {
        case Success(let v): return .Success(f(v))
        case Failure(let s): return .Failure(s)
        }
    }
    
    public func flatMap<T>(f : A -> Result<T>) -> Result<T> {
        switch self {
        case Success(let v): return f(v)
        case Failure(let s): return .Failure(s)
        }
    }
    
    public var isSuccess : Bool {
        switch self {
        case .Success(_): return true
        case .Failure(_): return false
        }
    }
    
    public var isFailure : Bool {
        switch self {
        case .Success(_): return false
        case .Failure(_): return true
        }
    }
    
    public func ifSuccess(f : A -> Void) -> Result<A> {
        switch self {
        case Success(let v): f(v)
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
        case Success(let v): return v
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

public func join<T, U>(t : Result<T>, u : Result<U>) -> Result<(T, U)> {
    switch (t, u) {
    case let (.Success(tValue), .Success(uValue)): return Success((tValue, uValue))
    case let (.Success(_), .Failure(error)): return Failure(error)
    case let (.Failure(error), .Success(_)): return Failure(error)
    case let (.Failure(error), .Failure(_)): return Failure(error)
    }
}

public func join<T>(results : [Result<T>]) -> Result<[T]> {
    var values : [T] = []
    for result in results {
        switch result {
        case let .Success(v): values.append(v)
        case let .Failure(e): return Failure(e)
        }
    }
    return Success(values)
}

public func Success<A>(v : A) -> Result<A> {
    return Result.Success(v)
}

public func Failure<A>(e : NSError? = nil) -> Result<A> {
    return Result.Failure(e ?? NSError.oex_unknownError())
}

extension Optional {
    
    /// Converts an optional to an error, using `error` if the `self` is `nil`
    func toResult(@autoclosure error : Void -> NSError?) -> Result<Wrapped> {
        if let v = self {
            return Success(v)
        }
        else {
            return Failure(error() ?? NSError.oex_unknownError())
        }
    }
    
    func toResult() -> Result<Wrapped> {
        return toResult(NSError.oex_unknownError())
    }
}