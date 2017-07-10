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
    public var maximumButtonWidth: CGFloat?
    public var minimumButtonWidth: CGFloat?
    
    // The vertical alignment mode used for when a button image and title are present.
    public var buttonVerticalAlignment: SwipeVerticalAlignment = .centerFirstBaseline
    
    // The amount of space, in points, between the border and the button image or title.
    public var buttonPadding: CGFloat?
    
    // The amount of space, in points, between the button image and the button title.
    public var buttonSpacing: CGFloat?
    
    // Constructs a new `SwipeTableOptions` instance with default options.
    public init() {}
}

// Describes which side of the cell that the action buttons will be displayed.
public enum SwipeActionsOrientation: CGFloat {
    // The left side of the cell.
    case left = -1
    
    // The right side of the cell.
    case right = 1
    
    var scale: CGFloat {
        return rawValue
    }
}

// Describes the alignment mode used when action button images and titles are provided.
public enum SwipeVerticalAlignment {
    // This mode will ensure the image and first line of each button title and consistently aligned across the swipe view.
    case centerFirstBaseline
    
    // Buttons with varying number of lines will not be consistently aligned across the swipe view.
    case center
}
