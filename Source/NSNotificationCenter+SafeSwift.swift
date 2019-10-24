//
//  NSNotificationCenter+SafeSwift.swift
//  edX
//
//  Created by Akiva Leffert on 5/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private class NotificationListener : NSObject, Removable {
    var action : ((NSNotification, Removable) -> Void)?
    var removeAction : ((NotificationListener) -> Void)?

    @objc func notificationFired(notification : NSNotification) {
        self.action?(notification, self)
    }
    
    func remove() {
        NotificationCenter.default.removeObserver(self)
        self.removeAction?(self)
        self.action = nil
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


extension NotificationCenter {
    @discardableResult public func oex_addObserver<Observer : NSObject>(observer : Observer, name : String, action : @escaping (NSNotification, Observer, Removable) -> Void) -> Removable {
        return self.observer(observer: observer, name: name, action: action)
    }
    
    @discardableResult public func oex_addObserver<Observer : NSObject>(observer : Observer, name : String, object: Any, action : @escaping (NSNotification, Observer, Removable) -> Void) -> Removable {
        return self.observer(observer: observer, name: name, object: object, action: action)
    }
    
    private func observer<Observer : NSObject>(observer : Observer, name : String, object: Any? = nil, action : @escaping (NSNotification, Observer, Removable) -> Void) -> Removable {
        let listener = NotificationListener()
        listener.action = {[weak observer] (notification, removable) in
            if let observer = observer {
                action(notification, observer, removable)
            }
        }
        let removable = observer.oex_performAction {
            listener.remove()
        }
        addObserver(listener, selector: #selector(NotificationListener.notificationFired(notification:)), name: NSNotification.Name(rawValue: name), object: object)
        
        return BlockRemovable { removable.remove() }
    }
}

@discardableResult public func addNotificationObserver<Observer : NSObject>(observer : Observer, name : String, action : @escaping (NSNotification, Observer, Removable) -> Void) -> Removable {
    return NotificationCenter.default.oex_addObserver(observer: observer, name: name, action: action)
}
