//
//  Result.swift
//  edX
//
//  Created by Akiva Leffert on 5/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public enum Result<A> {
    case success(A)
    case failure(NSError)
    
    public func map<B>(_ f : (A) -> B) -> Result<B> {
        switch self {
        case .success(let v): return .success(f(v))
        case .failure(let s): return .failure(s)
        }
    }
    
    public func flatMap<T>(_ f : (A) -> Result<T>) -> Result<T> {
        switch self {
        case .success(let v): return f(v)
        case .failure(let s): return .failure(s)
        }
    }
    
    public var isSuccess : Bool {
        switch self {
        case .success(_): return true
        case .failure(_): return false
        }
    }
    
    public var isFailure : Bool {
        switch self {
        case .success(_): return false
        case .failure(_): return true
        }
    }
    
    @discardableResult public func ifSuccess(_ f : (A) -> Void) -> Result<A> {
        switch self {
        case .success(let v): f(v)
        case .failure(_): break
        }
        return self
    }
    
   @discardableResult public func ifFailure(_ f : (NSError) -> Void) -> Result<A> {
        switch self {
        case .success(_): break
        case .failure(let message): f(message)
        }
        return self
    }
    
    public var value : A? {
        switch self {
        case .success(let v): return v
        case .failure(_): return nil
        }
    }
    
    public var error : NSError? {
        switch self {
        case .success(_): return nil
        case let .failure(e): return e
        }
    }
}

public func join<T, U>(_ t : Result<T>, u : Result<U>) -> Result<(T, U)> {
    switch (t, u) {
    case let (.success(tValue), .success(uValue)): return .success((tValue, uValue))
    case let (.success(_), .failure(error)): return .failure(error)
    case let (.failure(error), .success(_)): return .failure(error)
    case let (.failure(error), .failure(_)): return .failure(error)
    }
}

public func join<T>(_ results : [Result<T>]) -> Result<[T]> {
    var values : [T] = []
    for result in results {
        switch result {
        case let .success(v): values.append(v)
        case let .failure(e): return .failure(e)
        }
    }
    return .success(values)
}

extension Optional {
    public func toResult(_ error: @autoclosure () -> NSError) -> Result<Wrapped> {
        switch self {
        case let .some(v): return .success(v)
        case .none: return .failure(error())
        }
    }
}
