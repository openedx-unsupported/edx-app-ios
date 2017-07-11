//
//  SwipeCellViewDelegate.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

public protocol SwipeCellViewDelegate: class {
    
    // The delegate for the actions to display in response to a swipe in the specified row.
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]?
    
    //  The delegate method for the display options to be used while presenting the action buttons.
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeCellViewOptions
    
    //func tableView(_ tableView: UITableView, swipActionBeginForRowAt indexPath: IndexPath)
    func tableView(_ tableView: UITableView, swipActionEndForRowAt indexPath: IndexPath)
    
}

 // Default implementation of `SwipeTableViewCellDelegate` methods
public extension SwipeCellViewDelegate {
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeCellViewOptions {
        return SwipeCellViewOptions()
    }
}
