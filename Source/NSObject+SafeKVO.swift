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
    let action : AnyObject -> Void
    var removeAction : (KVOListener -> Void)?
    
    init(action : AnyObject -> Void) {
        self.action = action
    }
    
    private override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let new = change?[NSKeyValueChangeNewKey] {
            self.action(new)
        }
    }
    
    func remove() {
        self.removeAction?(self)
        self.removeAction = nil
    }
    
    deinit {
        self.removeAction?(self)
    }
}

extension NSObject : NSObjectExtensions {}

extension NSObjectExtensions where Self : NSObject {
    
    func oex_addObserver<Observer : NSObject>(observer : Observer, forKeyPath keyPath: String, action: (Observer, Self, AnyObject) -> Void) -> Removable {
        var listener = KVOListener{[weak observer, weak self] v in
            if let observer = observer, owner = self {
                action(observer, owner, v)
            }
        }
        objc_setAssociatedObject(observer, &listener, listener, .OBJC_ASSOCIATION_RETAIN)
        self.addObserver(listener, forKeyPath: keyPath, options: .New, context: &listener)
        let deallocRemover = observer.oex_performActionOnDealloc { [weak listener] in
            listener?.remove()
        }
        
        listener.removeAction = {[weak observer, weak self] listener in
            var listener = listener
            self?.removeObserver(listener, forKeyPath: keyPath)
            if let observer = observer {
                objc_setAssociatedObject(observer, &listener, nil, .OBJC_ASSOCIATION_RETAIN)
            }
            deallocRemover.remove()
        }
        
        return listener
    }
}