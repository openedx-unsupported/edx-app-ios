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
public class Operation : NSOperation {
    private var _executing : Bool = false
    private var _finished : Bool = false
    
    public override var executing:Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    public override var finished:Bool {
        get { return _finished }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    /// Subclasses with generic arguments can't have methods seen by Objective-C and hence NSOperation.
    /// This class doesn't have generic arguments, so it's safe for other things to subclass.
    @objc public override func start() {
        self.executing = true
        self.finished = false
        performWithDoneAction {[weak self] in
            self?.executing = false
            self?.finished = true
        }
    }
    
    public override func cancel() {
        self.executing = false
        self.finished = true
    }
    
    /// Subclasses should implement this since they might not be able to implement -start directly if they
    /// have generic arguments. Call doneAction when your task is done
    public func performWithDoneAction(doneAction : () -> Void) {
        
    }
}
