//
//  Operation.swift
//  edX
//
//  Created by Akiva Leffert on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


/// Standard stub subclass of NSOperation.
/// Needed to give an indirection for classes that use features that prevent them from exposing methods
/// to Objective-C, like generics.
open class OEXOperation : Foundation.Operation {
    fileprivate var _executing : Bool = false
    fileprivate var _finished : Bool = false
    
    open override var isExecuting:Bool {
        get { return _executing }
        set {
            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    open override var isFinished:Bool {
        get { return _finished }
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    /// Subclasses with generic arguments can't have methods seen by Objective-C and hence NSOperation.
    /// This class doesn't have generic arguments, so it's safe for other things to subclass.
    @objc open override func start() {
        self.isExecuting = true
        self.isFinished = false
        performWithDoneAction {[weak self] in
            self?.isExecuting = false
            self?.isFinished = true
        }
    }
    
    open override func cancel() {
        self.isExecuting = false
        self.isFinished = true
    }
    
    /// Subclasses should implement this since they might not be able to implement -start directly if they
    /// have generic arguments. Call doneAction when your task is done
    open func performWithDoneAction(_ doneAction : @escaping() -> Void) {
        
    }
}
