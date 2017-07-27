//
//  SwipeCellActionView.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit


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

enum SwipeState: Int {
    case initial = 0
    case left
    case right
    case animatingToInitial
    
    init(orientation: SwipeActionsOrientation) {
        self = orientation == .left ? .left : .right
    }
    
    var isActive: Bool { return self != .initial }
}

protocol SwipeActionsViewDelegate: class {
    func swipeActionsView(_ swipeCellActionView: SwipeCellActionView, didSelect action: SwipeActionButton)
}

class SwipeCellActionView: UIView {

    weak var delegate: SwipeActionsViewDelegate?
    
    let orientation: SwipeActionsOrientation
    private var buttons: [SwipeActionButton] = []
    private var minimumButtonWidth: CGFloat = 0
    var visibleWidth: CGFloat = 0
    var expanded: Bool = false
    
    private var maximumImageHeight: CGFloat {
        return buttons.reduce(0, { initial, next in max(initial, next.image?.size.height ?? 0) })
    }
    
    var preferredWidth: CGFloat {
        return minimumButtonWidth * CGFloat(buttons.count)
    }
    
    private var contentSize: CGSize {
        return CGSize(width: visibleWidth, height: bounds.height)
        
    }
    
    init(maxSize: CGSize, orientation: SwipeActionsOrientation, actions: [SwipeActionButton]) {
        self.orientation = orientation
        self.buttons = actions.reversed()
        
        
        super.init(frame: .zero)
        
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.init(red: 203.0/255.0, green: 7.0/255.0, blue: 18.0/255.0, alpha: 1.0)
        
        buttons = addButtons(for: self.buttons, withMaximum: maxSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addButtons(for actions: [SwipeActionButton], withMaximum size: CGSize) -> [SwipeActionButton] {
        let buttons: [SwipeActionButton] = actions.map({ actionButton in
            actionButton.addTarget(self, action: #selector(actionTapped(button:)), for: .touchUpInside)
            actionButton.autoresizingMask = [.flexibleHeight, orientation == .right ? .flexibleRightMargin : .flexibleLeftMargin]
            actionButton.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            return actionButton
        })
        
        let maximum = (size.width - 30) / CGFloat(actions.count)
        minimumButtonWidth = buttons.reduce(74, { initial, next in max(initial, next.preferredWidth(maximum: maximum)) })
        
        buttons.enumerated().forEach { (index, button) in
            let frame = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.height))
            button.frame = (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft) ? CGRect(x: frame.width - minimumButtonWidth, y: 0, width: minimumButtonWidth, height: frame.height) : CGRect(x: 0, y: 0, width: minimumButtonWidth, height: frame.height)
            addSubview(button)
            button.setMaximumImageHeight(maxImageHeight: maximumImageHeight)
        }
        
        return buttons
    }
    
    func actionTapped(button: SwipeActionButton) {
        guard let index = buttons.index(of: button) else { return }
        
        delegate?.swipeActionsView(self, didSelect: buttons[index])
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if expanded {
            subviews.last?.frame.origin.x = 0 + bounds.origin.x
        }
    }
}
