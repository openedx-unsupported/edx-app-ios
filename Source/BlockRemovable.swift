//
//  BlockRemovable.swift
//  edX
//
//  Created by Akiva Leffert on 5/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

// Simple removable that just executes an action on remove
public class BlockRemovable : NSObject, OEXRemovable {
    private var action : (Void -> Void)?
    
    public init(action : Void -> Void) {
        self.action = action
    }
    
    public func remove() {
        self.action?()
        action = nil
    }

}
