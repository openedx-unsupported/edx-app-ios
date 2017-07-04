//
//  SwipeAction.swift
//
//  Created by Jeremy Koch
//  Copyright © 2017 Jeremy Koch. All rights reserved.
//

import UIKit

/**
 The `SwipeAction` object defines a single action to present when the user swipes horizontally in a table row.
 
 This class lets you define one or more custom actions to display for a given row in your table. Each instance of this class represents a single action to perform and includes the text, formatting information, and behavior for the corresponding button.
 */
public class SwipeAction: NSObject {
    /// An optional unique action identifier.
    public var identifier: String?
    
    /// The title of the action button.
    ///
    /// - note: You must specify a title or an image.
    public var title: String?
    
    /// The object that is notified as transitioning occurs.
    //public var transitionDelegate: SwipeActionTransitioning?
    
    /// The font to use for the title of the action button.
    ///
    /// - note: If you do not specify a font, a 15pt system font is used.
    public var font: UIFont?
    
    /// The text color of the action button.
    ///
    /// - note: If you do not specify a color, white is used.
    public var textColor: UIColor?
    
    /// The image used for the action button.
    ///
    /// - note: You must specify a title or an image.
    public var image: UIImage?
    
    /// The highlighted image used for the action button.
    ///
    /// - note: If you do not specify a highlight image, the default `image` is used for the highlighted state.
    public var highlightedImage: UIImage?
    
    /// The closure to execute when the user taps the button associated with this action.
    public var handler: ((SwipeAction, IndexPath) -> Void)?
    
    /// The background color of the action button.
    ///
    /// - note: Use this property to specify the background color for your button. If you do not specify a value for this property, the framework assigns a default color based on the value in the style property.
    public var backgroundColor: UIColor?
  
    /// The highlighted background color of the action button.
    ///
    /// - note: Use this property to specify the highlighted background color for your button.
    public var highlightedBackgroundColor: UIColor?


    /**
     Constructs a new `SwipeAction` instance.
     - parameter title: The title of the action button.
     - parameter handler: The closure to execute when the user taps the button associated with this action.
    */
    public init(title: String?, handler: ((SwipeAction, IndexPath) -> Void)?) {
        self.title = title
        self.handler = handler
    }
    
}
