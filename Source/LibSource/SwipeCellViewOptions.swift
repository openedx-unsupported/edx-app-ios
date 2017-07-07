//
//  SwipeCellViewOptions.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

public struct SwipeCellViewOptions {

    // The background color behind the action buttons.
    public var backgroundColor: UIColor?
    
    // The largest allowable button width - note: By default, the value is set to the table view divided by the number of action buttons minus some additional padding. If the value is set to 0, then word wrapping will not occur and the buttons will grow as large as needed to fit the entire title/image.
    public var maximumButtonWidth: CGFloat?
    
    // The smallest allowable button width - note: By default, the system chooses an appropriate size.
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
    // All actions will be inspected and the tallest image and first baseline offset of title text will be used to create the alignment rectangle.
    // This mode will ensure the image and first line of each button title and consistently aligned across the swipe view.
    case centerFirstBaseline
    
    // The action button image height and full title height are used to create the aligment rectange.
    // Buttons with varying number of lines will not be consistently aligned across the swipe view.
    case center
}
