//
//  Observeable.swift
//  edX
//
//  Created by Muhammad Umer on 24/03/2021.
//  Copyright © 2021 edX. All rights reserved.
//
// https://colindrake.me/post/an-observable-pattern-implementation-in-swift/
// https://github.com/cfdrake/swift-observables-example/blob/master/Swift%20Observation.playground/Contents.swift

import Foundation

protocol ObservableProtocol {
    associatedtype T
    var value: T { get set }
    func subscribe(observer: AnyObject, block: @escaping (_ newValue: T, _ oldValue: T) -> ())
    func unsubscribe(observer: AnyObject)
}

public final class Observable<T>: ObservableProtocol {
    typealias ObserverBlock = (_ newValue: T, _ oldValue: T) -> ()
    typealias ObserversEntry = (observer: AnyObject, block: ObserverBlock)
    private var observers: Array<ObserversEntry>
    
    init(_ value: T) {
        self.value = value
        observers = []
    }
    
    var value: T {
        didSet {
            observers.forEach { (entry: ObserversEntry) in
                let (_, block) = entry
                block(value, oldValue)
            }
        }
    }
    
    func subscribe(observer: AnyObject, block: @escaping ObserverBlock) {
        let entry: ObserversEntry = (observer: observer, block: block)
        observers.append(entry)
    }
    
    func unsubscribe(observer: AnyObject) {
        let filtered = observers.filter { entry in
            let (owner, _) = entry
            return owner !== observer
        }
        
        observers = filtered
    }
}
