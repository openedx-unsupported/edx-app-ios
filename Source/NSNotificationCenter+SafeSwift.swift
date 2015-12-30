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
    var removeAction : (NotificationListener -> Void)?

    @objc func notificationFired(notification : NSNotification) {
        self.action?(notification, self)
    }
    
    func remove() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.removeAction?(self)
        self.action = nil
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}


extension NSNotificationCenter {
    func oex_addObserver<Observer : NSObject>(observer : Observer, name : String, action : (NSNotification, Observer, Removable) -> Void) -> Removable {
        let listener = NotificationListener()
        listener.action = {[weak observer] (notification, removable) in
            if let observer = observer {
                action(notification, observer, removable)
            }
        }
        let removable = observer.oex_performActionOnDealloc {
            listener.remove()
        }
        self.addObserver(listener, selector: "notificationFired:", name: name, object: nil)
        
        return BlockRemovable { removable.remove() }
    }
}

public func addNotificationObserver<Observer : NSObject>(observer : Observer, name : String, action : (NSNotification, Observer, Removable) -> Void) -> Removable {
    return NSNotificationCenter.defaultCenter().oex_addObserver(observer, name: name, action: action)
}
