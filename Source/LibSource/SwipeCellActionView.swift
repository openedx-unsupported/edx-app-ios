//
//  SwipeCellActionView.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

enum SwipeState: Int {
    case initialPosition = 0
    case left
    case right
    case animatingToInitialPosition
    
    init(orientation: SwipeActionsOrientation) {
        self = orientation == .left ? .left : .right
    }
    
    var isActive: Bool { return self != .initialPosition }
}

protocol SwipeActionsViewDelegate: class {
    func swipeActionsView(_ swipeCellActionView: SwipeCellActionView, didSelect action: SwipeAction)
}

class SwipeCellActionView: UIView {

    weak var delegate: SwipeActionsViewDelegate?
    
    var expansionAnimator: SwipeAnimator?
    let orientation: SwipeActionsOrientation
    let actions: [SwipeAction]
    let options: SwipeCellViewOptions
    var buttons: [SwipeActionButton] = []
    var minimumButtonWidth: CGFloat = 0
    var visibleWidth: CGFloat = 0
    
    var maximumImageHeight: CGFloat {
        return actions.reduce(0, { initial, next in max(initial, next.image?.size.height ?? 0) })
    }
    
    var preferredWidth: CGFloat {
        return minimumButtonWidth * CGFloat(actions.count)
    }
    
    var contentSize: CGSize {
        return CGSize(width: visibleWidth, height: bounds.height)
        
    }
    
    var expanded: Bool = false
    
    init(maxSize: CGSize, options: SwipeCellViewOptions, orientation: SwipeActionsOrientation, actions: [SwipeAction]) {
        self.options = options
        self.orientation = orientation
        self.actions = actions.reversed()
        
        super.init(frame: .zero)
        
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = options.backgroundColor ?? #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        
        buttons = addButtons(for: self.actions, withMaximum: maxSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addButtons(for actions: [SwipeAction], withMaximum size: CGSize) -> [SwipeActionButton] {
        let buttons: [SwipeActionButton] = actions.map({ action in
            let actionButton = SwipeActionButton(action: action)
            actionButton.addTarget(self, action: #selector(actionTapped(button:)), for: .touchUpInside)
            actionButton.autoresizingMask = [.flexibleHeight, orientation == .right ? .flexibleRightMargin : .flexibleLeftMargin]
            actionButton.spacing = options.buttonSpacing ?? 8
            actionButton.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            return actionButton
        })
        
        let maximum = options.maximumButtonWidth ?? (size.width - 30) / CGFloat(actions.count)
        minimumButtonWidth = buttons.reduce(options.minimumButtonWidth ?? 74, { initial, next in max(initial, next.preferredWidth(maximum: maximum)) })
        
        buttons.enumerated().forEach { (index, button) in
            let frame = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.height))
            button.frame = (UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft) ? CGRect(x: frame.width - minimumButtonWidth, y: 0, width: minimumButtonWidth, height: frame.height) : CGRect(x: 0, y: 0, width: minimumButtonWidth, height: frame.height)
            addSubview(button)
            button.maximumImageHeight = maximumImageHeight
            button.verticalAlignment = options.buttonVerticalAlignment
        }
        
        return buttons
    }
    
    func actionTapped(button: SwipeActionButton) {
        guard let index = buttons.index(of: button) else { return }
        
        delegate?.swipeActionsView(self, didSelect: actions[index])
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if expanded {
            subviews.last?.frame.origin.x = 0 + bounds.origin.x
        }
    }
}
