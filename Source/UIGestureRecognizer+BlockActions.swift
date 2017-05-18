//
//  UIGestureRecognizer+BlockActions.swift
//  edX
//
//  Created by Akiva Leffert on 6/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private class GestureListener : Removable {
    let token = malloc(1)
    var action : ((UIGestureRecognizer) -> Void)?
    var removeAction : ((GestureListener) -> Void)?
    
    deinit {
        free(token)
    }
    
    @objc func gestureFired(gesture : UIGestureRecognizer) {
        self.action?(gesture)
    }
    
    func remove() {
        removeAction?(self)
    }
}

protocol GestureActionable {
    init(target : AnyObject?, action : Selector)
}

extension UIGestureRecognizer : GestureActionable {}

extension GestureActionable where Self : UIGestureRecognizer {
    
    init(action : @escaping (Self) -> Void) {
        self.init(target: nil, action: nil)
        addAction(action: action)
    }
    
    init(target : AnyObject?, action : Selector) {
        self.init(target: nil, action: nil)
    }
    
    @discardableResult func addAction(action : @escaping (Self) -> Void) -> Removable {
        let listener = GestureListener()
        listener.action = {(gesture : UIGestureRecognizer) in
            if let gesture = gesture as? Self {
                action(gesture)
            }
        }
        objc_setAssociatedObject(self, listener.token, listener, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        listener.removeAction = {[weak self] (listener : GestureListener) in
            self?.removeTarget(listener, action: nil)
            objc_setAssociatedObject(self, listener.token, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        self.addTarget(listener, action: #selector(GestureListener.gestureFired(gesture :)))
        
        return listener
    }
}

