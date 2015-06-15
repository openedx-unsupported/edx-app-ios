//
//  Stream.swift
//  edX
//
//  Created by Akiva Leffert on 6/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private class Listener<A> : Removable, Equatable {
    private var removeAction : (Listener<A> -> Void)?
    private var action : (A -> Void)?
    
    init(action : A -> Void, removeAction : Listener<A> -> Void) {
        self.action = action
        self.removeAction = removeAction
    }
    
    func remove() {
        self.removeAction?(self)
        self.removeAction = nil
        self.action = nil
    }
}

private func == <A>(lhs : Listener<A>, rhs : Listener<A>) -> Bool {
    // Want to use pointer equality for equality
    return lhs === rhs
}

// MARK: Reading Streams
public class Stream<A> {
    public private(set) var value : A?
    private var listeners : [Listener<A>] = []
    
    /// not meant to be instantiated, since it has no way to notify listeners
    private init() {
    }
    
    public init(value : A) {
        self.value = value
    }
    
    public func addObserver(observer : NSObject, fireIfValuePresent : Bool = true, action : A -> Void) -> Removable {
        let listener = Listener(action: action) {[weak self] (listener : Listener<A>) in
            if let listeners = self?.listeners, index = find(listeners, listener) {
                self?.listeners.removeAtIndex(index)
            }
        }
        listeners.append(listener)
        
        observer.oex_performActionOnDealloc {
            listener.remove()
        }
        
        if let value = self.value where fireIfValuePresent {
            action(value)
        }
        
        return BlockRemovable {
            listener.remove()
        }
    }
    
    func map<B>(f : A -> B) -> Stream<B> {
        let sink = Sink<B>()
        addObserver(sink.token) {[weak sink] value in
            sink?.put(f(value))
        }
        return sink
    }
}


// MARK: Writing Streams
public class Sink<A> : Stream<A> {
    
    // This gives us an NSObject with the same lifetime as our
    // sink so that we can associate a removal action for when the sink gets deallocated
    private let token = NSObject()
    
    override public init() {
        super.init()
    }
    
    public func put(value : A) {
        self.value = value
        for listener in listeners {
            listener.action?(value)
        }
    }
}

// Sink that automatically cancels an operation when it deinits
public class CancellingSink<A> : Sink<A> {
    let removable : Removable
    public init(removable : Removable) {
        self.removable = removable
        super.init()
    }
    
    deinit {
        removable.remove()
    }
}

// MARK: Combining Streams


// This is different from an option, since you can't nest nils,
// so an A?? could resolve to nil and we wouldn't be able to detect that case
private enum Resolution<A> {
    case Unresolved
    case Resolved(A)
}

/// Combine a pair of streams into a stream of pairs.
/// After the initial load, the stream will update whenever either of the substreams updates
public func join<T, U>(t : Stream<T>, u: Stream<U>) -> Stream<(T, U)> {
    let sink = Sink<(T, U)>()
    var tBox = MutableBox<Resolution<T>>(.Unresolved)
    var uBox = MutableBox<Resolution<U>>(.Unresolved)
    
    t.addObserver(sink.token) {[weak sink] tValue in
        tBox.value = .Resolved(tValue)
        
        switch uBox.value {
        case let .Resolved(uValue):
            sink?.put((tValue, uValue))
        case .Unresolved:
            break
        }
    }
    
    u.addObserver(sink.token) {[weak sink] uValue in
        uBox.value = .Resolved(uValue)
        
        switch tBox.value {
        case let .Resolved(tValue):
            sink?.put((tValue, uValue))
        case .Unresolved:
            break
        }
    }
    
    return sink
}

/// Combine an array of streams into a stream of arrays.
/// After the initial load, the stream will update whenever any of the substreams updates.
public func join<T>(streams : [Stream<T>]) -> Stream<[T]> {
    let sink = Sink<[T]>()
    let pairs = streams.map {(stream : Stream<T>) -> (box : MutableBox<Resolution<T>>, stream : Stream<T>) in
        let box = MutableBox<Resolution<T>>(.Unresolved)
        return (box : box, stream : stream)
    }
    
    let boxes = pairs.map { return $0.box }
    for (box, stream) in pairs {
        stream.addObserver(sink.token) {[weak sink] value in
            box.value = .Resolved(value)
            let results = boxes.mapOrFailIfNil {(box : MutableBox<Resolution<T>>) -> T? in
                switch box.value {
                case .Unresolved: return nil
                case let .Resolved(v): return v
                }
            }
            
            if let r = results {
                sink?.put(r)
            }
        }
    }
    
    return sink
}

/// Passes on new values, but if there is already a value, drops errors on the floor
public func filterErrorsAfterValueFound<A>(stream : Stream<Result<A>>) -> Stream<Result<A>> {
    let sink = Sink<Result<A>>()
    stream.addObserver(sink.token) {[weak sink] r in
        if let value = r.value {
            sink?.put(Success(value))
        }
        else {
            if sink?.value == nil {
                sink?.put(r)
            }
        }
    }
    return sink
}
