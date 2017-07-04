//
//  SwipeCellViewDelegate.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

/**
 The `SwipeTableViewCellDelegate` protocol is adopted by an object that manages the display of action buttons when the cell is swiped.
 */
public protocol SwipeCellViewDelegate: class {
    /**
     Asks the delegate for the actions to display in response to a swipe in the specified row.
     
     - parameter tableView: The table view object which owns the cell requesting this information.
     
     - parameter indexPath: The index path of the row.
     
     - parameter orientation: The side of the cell requesting this information.
     
     - returns: An array of `SwipeAction` objects representing the actions for the row. Each action you provide is used to create a button that the user can tap.  Returning `nil` will prevent swiping for the supplied orientation.
     */
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]?
    
    /**
     Asks the delegate for the display options to be used while presenting the action buttons.
     
     - parameter tableView: The table view object which owns the cell requesting this information.
     
     - parameter indexPath: The index path of the row.
     
     - parameter orientation: The side of the cell requesting this information.
     
     - returns: A `SwipeCellViewOptions` instance which configures the behavior of the action buttons.
     
     - note: If not implemented, a default `SwipeCellViewOptions` instance is used.
     */
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeCellViewOptions
    
}

/**
 Default implementation of `SwipeTableViewCellDelegate` methods
 */
public extension SwipeCellViewDelegate {
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeCellViewOptions {
        return SwipeCellViewOptions()
    }
}
