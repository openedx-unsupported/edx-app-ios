//
//  SwipeAccessibilityCustomAction.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

extension SwipeCellView {
    
    open override func accessibilityElementCount() -> Int {
        guard state != .center else {
            return super.accessibilityElementCount()
        }
        
        return 1
    }
    
    open override func accessibilityElement(at index: Int) -> Any? {
        guard state != .center else {
            return super.accessibilityElement(at: index)
        }
        
        return actionsView
    }
    
    open override func index(ofAccessibilityElement element: Any) -> Int {
        guard state != .center else {
            return super.index(ofAccessibilityElement: element)
        }
        
        return element is SwipeCellActionView ? 0 : NSNotFound
    }
    
    open override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            guard let tableView = tableView, let indexPath = tableView.indexPath(for: self) else {
                return super.accessibilityCustomActions
            }
            
            let leftActions = swipeCellViewDelegate?.tableView(tableView, editActionsForRowAt: indexPath, for: .left) ?? []
            let rightActions = swipeCellViewDelegate?.tableView(tableView, editActionsForRowAt: indexPath, for: .right) ?? []
            
            let actions = [rightActions.first, leftActions.first].flatMap({ $0 }) + rightActions.dropFirst() + leftActions.dropFirst()
            
            if actions.count > 0 {
                return actions.map({ SwipeAccessibilityCustomAction(action: $0,
                                                                    indexPath: indexPath,
                                                                    target: self,
                                                                    selector: #selector(performAccessibilityCustomAction(accessibilityCustomAction:))) })
            } else {
                return super.accessibilityCustomActions
            }
        }
        
        set {
            super.accessibilityCustomActions = newValue
        }
    }
    
    func performAccessibilityCustomAction(accessibilityCustomAction: SwipeAccessibilityCustomAction) -> Bool {
        
        let swipeAction = accessibilityCustomAction.action
        swipeAction.handler?(swipeAction, accessibilityCustomAction.indexPath)
        
        return true
    }
}

class SwipeAccessibilityCustomAction: UIAccessibilityCustomAction {
    let action: SwipeAction
    let indexPath: IndexPath
    
    init(action: SwipeAction, indexPath: IndexPath, target: Any, selector: Selector) {
        guard let name = action.accessibilityLabel ?? action.title ?? action.image?.accessibilityIdentifier else {
            fatalError("You must provide either a title or an image for a SwipeAction")
        }
        
        self.action = action
        self.indexPath = indexPath
        
        super.init(name: name, target: target, selector: selector)
    }
}
