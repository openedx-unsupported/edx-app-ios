//
//  SwipeAction.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

public class SwipeAction: NSObject {
    public var title: String?
    public var image: UIImage?
    
    // The closure to execute when the user taps the button associated with this action.
    public var handler: ((SwipeAction, IndexPath) -> Void)?
    
    public init(title: String?, handler: ((SwipeAction, IndexPath) -> Void)?) {
        self.title = title
        self.handler = handler
    }
}
