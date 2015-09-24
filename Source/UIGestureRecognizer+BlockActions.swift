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

protocol GestureActionable {}

extension UIGestureRecognizer : GestureActionable {}

extension GestureActionable where Self : UIGestureRecognizer {
    
    func addAction(action : Self -> Void) -> Removable {
        var listener = GestureListener()
        listener.action = {(gesture : UIGestureRecognizer) in
            if let gesture = gesture as? Self {
                action(gesture)
            }
        }
        objc_setAssociatedObject(self, &listener, listener, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        listener.removeAction = {[weak self] (var listener : GestureListener) in
            self?.removeTarget(listener, action: nil)
            objc_setAssociatedObject(self, &listener, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        self.addTarget(listener, action: Selector("gestureFired:"))
        
        return listener
    }
}

