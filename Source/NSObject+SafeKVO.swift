//
//  NSObject+SafeKVO.swift
//  edX
//
//  Created by Akiva Leffert on 12/4/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

protocol NSObjectExtensions {}

private class KVOListener : NSObject, Removable {
    let action : (AnyObject) -> Void
    var removeAction : ((KVOListener) -> Void)?
    var token = malloc(1)
    
    init(action : @escaping (AnyObject) -> Void) {
        self.action = action
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)  {
        if let new = change?[NSKeyValueChangeKey.newKey] {
            self.action(new as AnyObject)
        }
    }
    
    func remove() {
        self.removeAction?(self)
        self.removeAction = nil
    }
    
    deinit {
        self.removeAction?(self)
        free(token)
    }
}

extension NSObject : NSObjectExtensions {}

extension NSObjectExtensions where Self : NSObject {

    /// Adds ``observer`` as a KVO watcher for the receiver. Note that this causes the observer to retain the
    /// observed object.
    // We have to do this retain because the KVO system will crash if you don't remove an observer
    // before deallocating the observed object.
    // There's no cycle here though, since the observed object only retains the observer weakly
    @discardableResult func oex_addObserver<Observer : NSObject>(observer : Observer, forKeyPath keyPath: String, action: @escaping (Observer, Self, AnyObject) -> Void) -> Removable {
        let listener = KVOListener{[weak observer] v in
            if let observer = observer {
                action(observer, self, v)
            }
        }
        objc_setAssociatedObject(observer, listener.token, listener, .OBJC_ASSOCIATION_RETAIN)
        self.addObserver(listener, forKeyPath: keyPath, options: .new, context: listener.token)
        let deallocRemover = observer.oex_performAction { [weak listener] in
            listener?.remove()
        }
        
        listener.removeAction = {[weak observer, weak self] listener in
            self?.removeObserver(listener, forKeyPath: keyPath)
            if let observer = observer {
                objc_setAssociatedObject(observer, listener.token, nil, .OBJC_ASSOCIATION_RETAIN)
            }
            deallocRemover.remove()
        }
        
        return listener
    }
}

