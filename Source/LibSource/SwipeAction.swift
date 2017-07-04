//
//  SwipeAction.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

/*
    The `SwipeAction` object defines a single action to present when the user swipes horizontally in a table row.
    This class lets you define one or more custom actions to display for a given row in your table. Each instance of this class represents a single action to perform and includes the text, formatting information, and behavior for the corresponding button.
*/
public class SwipeAction: NSObject {
    public var identifier: String?
    public var title: String?
    public var font: UIFont?
    public var textColor: UIColor?
    public var image: UIImage?
    public var highlightedImage: UIImage?
    public var highlightedBackgroundColor: UIColor?
    public var backgroundColor: UIColor?
    
    // The closure to execute when the user taps the button associated with this action.
    public var handler: ((SwipeAction, IndexPath) -> Void)?
    
    public init(title: String?, handler: ((SwipeAction, IndexPath) -> Void)?) {
        self.title = title
        self.handler = handler
    }
}
