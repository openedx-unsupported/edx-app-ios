//
//  Removable.swift
//  edX
//
//  Created by Akiva Leffert on 6/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public protocol Removable {
    func remove()
}

// Simple removable that just executes an action on remove
open class BlockRemovable : Removable {
    fileprivate var action : (() -> Void)?
    
    public init(action : @escaping () -> Void) {
        self.action = action
    }
    
    open func remove() {
        self.action?()
        action = nil
    }
    
}
