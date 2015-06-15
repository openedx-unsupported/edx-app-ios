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
public class BlockRemovable : Removable {
    private var action : (Void -> Void)?
    
    public init(action : Void -> Void) {
        self.action = action
    }
    
    public func remove() {
        self.action?()
        action = nil
    }
    
}