//
//  SwipeCellViewOptions.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

public struct SwipeCellViewOptions {

    public var backgroundColor: UIColor?
    
    // The vertical alignment mode used for when a button image and title are present.
    //public var buttonVerticalAlignment: SwipeVerticalAlignment = .centerFirstBaseline
    
    // The amount of space, in points, between the border and the button image or title.
    public var buttonPadding: CGFloat?
    
    // The amount of space, in points, between the button image and the button title.
    public var buttonSpacing: CGFloat?
    
    // Constructs a new `SwipeTableOptions` instance with default options.
    public init() {}
}
