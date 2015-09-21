//
//  UIGestureRecognizer+BlockActions.swift
//  edX
//
//  Created by Akiva Leffert on 6/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private class GestureListener : NSObject, Removable {
    var token : Void  = ()
    var action : (UIGestureRecognizer -> Void)?
    var removeAction : (GestureListener -> Void)?
    
    @objc func gestureFired(gesture : UIGestureRecognizer) {
        self.action?(gesture)
    }
    
    func remove() {
        removeAction?(self)
    }
}

// TODO revisit this when we adopt Swift 2.0
// to see if it's possible to get rid of the dynamic cast
extension UIGestureRecognizer {
    func addAction<T : UIGestureRecognizer>(action : T -> Void) -> Removable {
        if let gesture = self as? T {
            return addActionForGesture(gesture, action: action)
        }
        else {
            assert(false, "Gesture type mismatch")
            return BlockRemovable {}
        }
    }
}

func addActionForGesture<T : UIGestureRecognizer>(gesture : T, action : T -> Void) -> Removable {
    var listener = GestureListener()
    listener.action = {(gesture : UIGestureRecognizer) in
        if let gesture = gesture as? T {
            action(gesture)
        }
    }
    objc_setAssociatedObject(gesture, &listener, listener, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    listener.removeAction = {[weak gesture] (var listener : GestureListener) in
        objc_setAssociatedObject(gesture, &listener, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    gesture.addTarget(listener, action: Selector("gestureFired:"))
    
    return listener
}

