//
//  Stream.swift
//  edX
//
//  Created by Akiva Leffert on 6/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

// Bookkeeping class for a listener of a stream
private class Listener<A> : Removable, Equatable {
    private var removeAction : (Listener<A> -> Void)?
    private var action : (Result<A> -> Void)?
    
    init(action : Result<A> -> Void, removeAction : Listener<A> -> Void) {
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
    /// We want to use pointer equality for equality since the main thing
    /// we care about for listeners is are they the same instance so we can remove them
    return lhs === rhs
}

// MARK: Reading Streams

// This should really be a protocol with Sink a concrete instantiation of that protocol
// But unfortunately Swift doesn't currently support generic protocols
// Revisit this if it ever does

/// A stream of values and errors. Note that, like all objects, a stream will get deallocated if it has no references.
public class Stream<A> {
    private let dependencies : [AnyObject]
    private(set) var lastResult : Result<A>?
    
    public var value : A? {
        return lastResult?.value
    }
    
    public var error : NSError? {
        return lastResult?.error
    }
    
    private var listeners : [Listener<A>] = []
    
    /// Make a new stream.
    ///
    /// :param: dependencies A list of objects that this stream will retain.
    /// Typically this is a stream or streams that this object is listening to so that
    /// they don't get deallocated.
    public init(dependencies : [AnyObject] = []) {
        self.dependencies = dependencies
    }
    
    /// Seed a new stream with a constant value.
    ///
    /// :param: value The initial value of the stream.
    public convenience init(value : A) {
        self.init()
        self.lastResult = Success(value)
    }
    
    /// Seed a new stream with a constant error.
    ///
    /// :param: error The initial error for the stream
    public convenience init(error : NSError) {
        self.init()
        self.lastResult = Failure(error)
    }
    
    /// Add a listener to a stream.
    ///
    /// :param: owner The listener will automatically be removed when owner gets deallocated.
    /// :param: fireIfLoaded If true then this will fire the listener immediately if the signal has already received a value.
    /// :param: action The action to fire when the stream receives a result.
    public func listen(owner : NSObject, fireIfAlreadyLoaded : Bool = true, action : Result<A> -> Void) -> Removable {
        let listener = Listener(action: action) {[weak self] (listener : Listener<A>) in
            if let listeners = self?.listeners, index = find(listeners, listener) {
                self?.listeners.removeAtIndex(index)
            }
        }
        listeners.append(listener)
        
        let removable = owner.oex_performActionOnDealloc {
            listener.remove()
        }
        
        if let value = self.value where fireIfAlreadyLoaded {
            action(Success(value))
        }
        else if let error = self.error where fireIfAlreadyLoaded {
            action(Failure(error))
        }
        
        return BlockRemovable {
            removable.remove()
            listener.remove()
        }
    }
    
    /// Add a listener to a stream.
    ///
    /// :param: owner The listener will automatically be removed when owner gets deallocated.
    /// :param: fireIfLoaded If true then this will fire the listener immediately if the signal has already received a value. If false the listener won't fire until a new result is supplied to the stream.
    /// :param: success The action to fire when the stream receives a Success result.
    /// :param: success The action to fire when the stream receives a Failure result.
    public func listen(owner : NSObject, fireIfAlreadyLoaded : Bool = true, success : A -> Void, failure : NSError -> Void) -> Removable {
        return listen(owner, fireIfAlreadyLoaded: fireIfAlreadyLoaded) {
            switch $0 {
            case let .Success(v): success(v.value)
            case let .Failure(e): failure(e)
            }
        }
    }
    
    /// Add a listener to a stream. When the listener fires it will be removed automatically.
    ///
    /// :param: owner The listener will automatically be removed when owner gets deallocated.
    /// :param: fireIfLoaded If true then this will fire the listener immediately if the signal has already received a value. If false the listener won't fire until a new result is supplied to the stream.
    /// :param: success The action to fire when the stream receives a Success result.
    /// :param: success The action to fire when the stream receives a Failure result.
    public func listenOnce(owner : NSObject, fireIfAlreadyLoaded : Bool = true, success : A -> Void, failure : NSError -> Void) -> Removable {

        return listenOnce(owner, fireIfAlreadyLoaded: fireIfAlreadyLoaded, action : {
            switch $0 {
            case let .Success(box): success(box.value)
            case let .Failure(error): failure(error)
            }
        })
    }
    
    public func listenOnce(owner : NSObject, fireIfAlreadyLoaded : Bool = true, action : Result<A> -> Void) -> Removable {
        let removable = listen(owner, fireIfAlreadyLoaded: fireIfAlreadyLoaded, action : action)
        let followup = listen(owner, fireIfAlreadyLoaded: fireIfAlreadyLoaded,
            action: {_ in
                removable.remove()
            }
        )
        return BlockRemovable {
            removable.remove()
            followup.remove()
        }
    }
    
    /// :returns: A filtered stream based on the receiver that will only fire the first time a success value is sent. Use this if you want to capture a value and *not* update when the next one comes in.
    public func firstSuccess() -> Stream<A> {
        let sink = Sink<A>(dependencies: [self])
        listen(sink.token) {[weak sink] result in
            if sink?.lastResult?.isFailure ?? true {
                sink?.send(result)
            }
        }
        return sink
    }
    
    
    /// :returns: A filtered stream based on the receiver that won't fire on errors after a value is loaded. It will fire if a new value comes through after a value is already loaded.
    public func dropFailuresAfterSuccess() -> Stream<A> {
        let sink = Sink<A>(dependencies: [self])
        listen(sink.token) {[weak sink] result in
            if sink?.lastResult == nil || result.isSuccess {
                sink?.send(result)
            }
        }
        return sink
    }
    
    /// Transforms a stream into a new stream. Failure results will pass through untouched.
    public func map<B>(f : A -> B) -> Stream<B> {
        let sink = Sink<B>(dependencies: [self])
        listen(sink.token) {[weak sink] result in
            sink?.send(result.map(f))
        }
        return sink
    }
    
    /// Transforms a stream into a new stream.
    public func flatMap<B>(f : A -> Result<B>) -> Stream<B> {
        let sink = Sink<B>(dependencies: [self])
        listen(sink.token) {[weak sink] current in
            let next = current.flatMap(f)
            sink?.send(next)
        }
        return sink
    }
    
    /// :returns: A stream that is automatically backed by a new stream whenever the receiver fires.
    public func transform<B>(f : A -> Stream<B>) -> Stream<B> {
        let backed = BackedStream<B>(dependencies: [self])
        listen(backed.token) {[weak backed] current in
            current.ifSuccess {
                backed?.backWithStream(f($0))
            }
        }
        return backed
    }
    
    /// Stream that calls a cancelation action if the stream gets deallocated.
    /// Use if you want to perform an action once no one is listening to a stream
    /// for example, an expensive operation or a network request
    /// :param: cancel The action to perform when this stream gets deallocated.
    public func autoCancel(cancelAction : Removable) -> Stream<A> {
        let sink = CancellingSink<A>(dependencies : [self], removable: cancelAction)
        listen(sink.token) {[weak sink] current in
            sink?.send(current)
        }
        return sink
    }
    
    /// Extends the lifetime of a stream until the first result received.
    ///
    /// :param: completion A completion that fires when the stream fires
    public func extendLifetimeUntilFirstResult(completion : Result<A> -> Void) {
        NSOperationQueue.mainQueue().addOperation(StreamWaitOperation(stream: self, completion: completion))
    }
    
    /// Constructs a stream that returns values from the receiver, but will return any values from *stream* until
    /// the first value is sent to the receiver. For example, if you're implementing a network cache, you want to
    /// return the value saved to disk, but only if the network request hasn't finished yet.
    public func cachedByStream(cacheStream : Stream<A>) -> Stream<A> {
        let sink = Sink<A>(dependencies: [cacheStream, self])
        listen(sink.token) {[weak sink] current in
            sink?.send(current)
        }
        
        cacheStream.listen(sink.token) {[weak sink, weak self] current in
            if self?.lastResult == nil {
                sink?.send(current)
            }
        }
        return sink
    }
}

// MARK: Writing Streams
/// A writable stream.
/// Sink is a separate type from stream to make it easy to control who can write to the stream.
/// If you need a writeble stream, typically you'll use a Sink internally, 
/// but upcast to stream outside of the relevant abstraction boundary
public class Sink<A> : Stream<A> {
    
    // This gives us an NSObject with the same lifetime as our
    // sink so that we can associate a removal action for when the sink gets deallocated
    private let token = NSObject()
    
    override public init(dependencies : [AnyObject] = []) {
        super.init(dependencies : dependencies)
    }
    
    public func send(value : A) {
        send(Success(value))
    }
    
    public func send(error : NSError) {
        send(Failure(error))
    }
    
    public func send(result : Result<A>) {
        self.lastResult = result
        
        for listener in listeners {
            listener.action?(result)
        }
    }
}

// Sink that automatically cancels an operation when it deinits
private class CancellingSink<A> : Sink<A> {
    let removable : Removable
    init(dependencies : [AnyObject] = [], removable : Removable) {
        self.removable = removable
        super.init(dependencies : dependencies)
    }
    
    deinit {
        removable.remove()
    }
}

/// A stream that is rewirable. This is shorthand for the pattern of having a variable
/// representing an optional stream that is imperatively updated.
/// Using a BackedStream lets you set listeners once and always have a
/// non-optional value to pass around that others can receive values from.
public class BackedStream<A> : Stream<A> {
    private let token = NSObject()
    private var backing : AnyObject?
    private var removeBackingAction : Removable?
    
    override public init(dependencies : [AnyObject] = []) {
        super.init(dependencies : dependencies)
    }
    
    /// Removes the old backing and adds a new one. When the backing stream fires so will this one.
    /// Think of this as rewiring a pipe from an old source to a new one.
    public func backWithStream(backing : Stream<A>) {
        removeBacking()
        self.backing = backing
        self.removeBackingAction = backing.listen(self.token) {[weak self] result in
            self?.send(result)
        }
    }
    
    public func removeBacking() {
        removeBackingAction?.remove()
        removeBackingAction = nil
        backing = nil
    }
    
    var hasBacking : Bool {
        return backing != nil
    }
    
    /// Send a new value to the stream.
    private func send(result : Result<A>) {
        self.lastResult = result
        
        for listener in listeners {
            listener.action?(result)
        }
    }
}

// MARK: Combining Streams

// This is different from an option, since you can't nest nils,
// so an A?? could resolve to nil and we wouldn't be able to detect that case
private enum Resolution<A> {
    case Unresolved
    case Resolved(Result<A>)
}

/// Combine a pair of streams into a stream of pairs.
/// The stream will both substreams have fired.
/// After the initial load, the stream will update whenever either of the substreams updates
public func joinStreams<T, U>(t : Stream<T>, u: Stream<U>) -> Stream<(T, U)> {
    let sink = Sink<(T, U)>(dependencies: [t, u])
    var tBox = MutableBox<Resolution<T>>(.Unresolved)
    var uBox = MutableBox<Resolution<U>>(.Unresolved)
    
    t.listen(sink.token) {[weak sink] tValue in
        tBox.value = .Resolved(tValue)
        
        switch uBox.value {
        case let .Resolved(uValue):
            sink?.send(join(tValue, uValue))
        case .Unresolved:
            break
        }
    }
    
    u.listen(sink.token) {[weak sink] uValue in
        uBox.value = .Resolved(uValue)
        
        switch tBox.value {
        case let .Resolved(tValue):
            sink?.send(join(tValue, uValue))
        case .Unresolved:
            break
        }
    }
    
    return sink
}

/// Combine an array of streams into a stream of arrays.
/// The stream will not fire until all substreams have fired.
/// After the initial load, the stream will update whenever any of the substreams updates.
public func joinStreams<T>(streams : [Stream<T>]) -> Stream<[T]> {
    let sink = Sink<[T]>(dependencies : streams)
    let pairs = streams.map {(stream : Stream<T>) -> (box : MutableBox<Resolution<T>>, stream : Stream<T>) in
        let box = MutableBox<Resolution<T>>(.Unresolved)
        return (box : box, stream : stream)
    }
    
    let boxes = pairs.map { return $0.box }
    for (box, stream) in pairs {
        stream.listen(sink.token) {[weak sink] value in
            box.value = .Resolved(value)
            let results = boxes.mapOrFailIfNil {(box : MutableBox<Resolution<T>>) -> Result<T>? in
                switch box.value {
                case .Unresolved: return nil
                case let .Resolved(v): return v
                }
            }
            
            if let r = results {
                sink?.send(join(r))
            }
        }
    }
    
    if streams.count == 0 {
        sink.send(Success([]))
    }
    
    return sink
}
