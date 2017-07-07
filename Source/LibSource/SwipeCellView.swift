//
//  SwipeCellView.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

open class SwipeCellView: UITableViewCell {
    
    /// The object that acts as the delegate of the `SwipeCellView`.
    public weak var swipeCellViewDelegate: SwipeCellViewDelegate?
    
    var animator: SwipeAnimator?
    var state = SwipeState.center
    var originalCenter: CGFloat = 0
    weak var tableView: UITableView?
    var actionsView: SwipeCellActionView?
    var originalLayoutMargins: UIEdgeInsets = .zero
    var panGestureRecognizer = UIPanGestureRecognizer()
    var tapGestureRecognizer = UITapGestureRecognizer()
    
    override open var center: CGPoint {
        didSet {
            actionsView?.visibleWidth = abs(frame.minX)
        }
    }
    
    open override var frame: CGRect {
        set { super.frame = state.isActive ? CGRect(origin: CGPoint(x: frame.minX, y: newValue.minY), size: newValue.size) : newValue }
        get { return super.frame }
    }
    
    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        panGestureRecognizer.addAction {[weak self]_ in
            self?.handlePan(gesture: (self?.panGestureRecognizer)!)
        }
        
        tapGestureRecognizer.addAction {[weak self]_ in
            self?.handleTap(gesture: (self?.tapGestureRecognizer)!)
        }
        panGestureRecognizer.delegate = self
        tapGestureRecognizer.delegate = self
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configure()
    }
    
    deinit {
        tableView?.panGestureRecognizer.removeTarget(self, action: nil)
    }
    
    func configure() {
        clipsToBounds = false
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(panGestureRecognizer)
    }
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        var view: UIView = self
        while let superview = view.superview {
            view = superview
            if let tableView = view as? UITableView {
                self.tableView = tableView
                tableView.panGestureRecognizer.removeTarget(self, action: nil)
                tableView.panGestureRecognizer.addTarget(self, action: #selector(handleTablePan(gesture:)))
                return
            }
        }
    }
    
    func handlePan(gesture: UIPanGestureRecognizer) {
        guard let target = gesture.view else { return }
        
        switch gesture.state {
            case .began:
                stopAnimatorIfNeeded()
                originalCenter = center.x
                if state == .center || state == .animatingToCenter {
                    let velocity = gesture.velocity(in: target)
                    let orientation: SwipeActionsOrientation = velocity.x > 0 ? .left : .right
                    showActionsView(for: orientation)
                }
            case .changed:
                guard let actionsView = actionsView else { return }
                target.center.x = gesture.elasticTranslation(in: target,
                                                             withLimit: CGSize(width: actionsView.preferredWidth, height: 0),
                                                             fromOriginalCenter: CGPoint(x: originalCenter, y: 0),
                                                             applyingRatio: 0.0).x
            case .ended:
                let velocity = gesture.velocity(in: target)
                state = targetState(forVelocity: velocity)
                let targetOffset = targetCenter(active: state.isActive)
                let distance = targetOffset - center.x
                let normalizedVelocity = velocity.x * 1.0 / distance
                animate(toOffset: targetOffset, withInitialVelocity: normalizedVelocity) { _ in
                    if self.state == .center {
                        self.reset()
                    }
                }
            default: break
        }
    }
    
    func hideSwipe(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        state = .animatingToCenter
        tableView?.setGestureEnabled(true)
        let targetCenter = self.targetCenter(active: false)
        if animated {
            animate(toOffset: targetCenter) { complete in
                self.reset()
                completion?(complete)
            }
        } else {
            center = CGPoint(x: targetCenter, y: self.center.y)
            reset()
        }
    }
    
    @discardableResult
    func showActionsView(for orientation: SwipeActionsOrientation) -> Bool {
        guard let tableView = tableView,
            let indexPath = tableView.indexPath(for: self),
            let actions = swipeCellViewDelegate?.tableView(tableView, editActionsForRowAt: indexPath, for: orientation),
            actions.count > 0
            else {
                return false
        }
        originalLayoutMargins = super.layoutMargins
        
        // Remove highlight and deselect any selected cells
        super.setHighlighted(false, animated: false)
        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        selectedIndexPaths?.forEach { tableView.deselectRow(at: $0, animated: false) }
        
        // Temporarily remove table gestures
        tableView.setGestureEnabled(false)
        configureActionsView(with: actions, for: orientation)
        return true
    }
    
    func configureActionsView(with actions: [SwipeAction], for orientation: SwipeActionsOrientation) {
        guard let tableView = tableView,
            let indexPath = tableView.indexPath(for: self) else { return }
        
        let options = swipeCellViewDelegate?.tableView(tableView, editActionsOptionsForRowAt: indexPath, for: orientation) ?? SwipeCellViewOptions()
        self.actionsView?.removeFromSuperview()
        self.actionsView = nil
        let actionsView = SwipeCellActionView(maxSize: bounds.size, options: options, orientation: orientation, actions: actions)
        actionsView.delegate = self
        addSubview(actionsView)
        let heightConstraint = NSLayoutConstraint(item: actionsView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0.0)
        let constantWidth = NSLayoutConstraint(item: actionsView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100.0)
        let verticalCentreConstraint = NSLayoutConstraint(item: actionsView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        var constraints: [NSLayoutConstraint] = [heightConstraint,constantWidth,verticalCentreConstraint]
        
        if orientation == .right {
            let rightConstraint = NSLayoutConstraint(item: actionsView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
            constraints.append(rightConstraint)
        }
        NSLayoutConstraint.activate(constraints)
        self.actionsView = actionsView
        state = .dragging
    }
    
    
    func animate(duration: Double = 0.7, toOffset offset: CGFloat, withInitialVelocity velocity: CGFloat = 0, completion: ((Bool) -> Void)? = nil) {
        stopAnimatorIfNeeded()
        layoutIfNeeded()
        let animator: SwipeAnimator = {
            if velocity != 0 {
                if #available(iOS 10, *) {
                    let velocity = CGVector(dx: velocity, dy: velocity)
                    let parameters = UISpringTimingParameters(mass: 1.0, stiffness: 100, damping: 18, initialVelocity: velocity)
                    return UIViewPropertyAnimator(duration: 0.0, timingParameters: parameters)
                } else {
                    return UIViewSpringAnimator(duration: duration, damping: 1.0, initialVelocity: velocity)
                }
            } else {
                if #available(iOS 10, *) {
                    return UIViewPropertyAnimator(duration: duration, dampingRatio: 1.0)
                } else {
                    return UIViewSpringAnimator(duration: duration, damping: 1.0)
                }
            }
        }()
        
        animator.addAnimations({
            self.center = CGPoint(x: offset, y: self.center.y)
            
            self.layoutIfNeeded()
        })
        
        if let completion = completion {
            animator.addCompletion(completion: completion)
        }
        
        self.animator = animator
        
        animator.startAnimation()
    }
    
    func stopAnimatorIfNeeded() {
        if animator?.isRunning == true {
            animator?.stopAnimation(true)
        }
    }
    
    func handleTap(gesture: UITapGestureRecognizer) {
        hideSwipe(animated: true)
    }
    
    func handleTablePan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            hideSwipe(animated: true)
        }
    }
    
    // Override so we can accept touches anywhere within the cell's minY/maxY.
    // This is required to detect touches on the `SwipeCellActionView` sitting alongside the
    // `SwipeCellView`.
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let superview = superview else { return false }
        
        let point = convert(point, to: superview)
        
        if !UIAccessibilityIsVoiceOverRunning() {
            for cell in tableView?.swipeCells ?? [] {
                if (cell.state == .left || cell.state == .right) && !cell.contains(point: point) {
                    tableView?.hideSwipeCell()
                    return false
                }
            }
        }
        
        return contains(point: point)
    }
    
    func contains(point: CGPoint) -> Bool {
        return point.y > frame.minY && point.y < frame.maxY
    }
    
    override open func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if state == .center {
            super.setHighlighted(highlighted, animated: animated)
        }
    }

    override open var layoutMargins: UIEdgeInsets {
        get {
            return frame.origin.x != 0 ? originalLayoutMargins : super.layoutMargins
        }
        set {
            super.layoutMargins = newValue
        }
    }
}

extension SwipeCellView: SwipeActionsViewDelegate {
    func targetState(forVelocity velocity: CGPoint) -> SwipeState {
        guard let actionsView = actionsView else { return .center }
        
        switch actionsView.orientation {
        case .left:
            return (velocity.x < 0 && !actionsView.expanded) ? .center : .left
        case .right:
            return (velocity.x > 0 && !actionsView.expanded) ? .center : .right
        }
    }
    
    func targetCenter(active: Bool) -> CGFloat {
        guard let actionsView = actionsView, active == true else { return bounds.midX }
        
        return bounds.midX - actionsView.preferredWidth * actionsView.orientation.scale
    }
    
    func reset() {
        state = .center
        tableView?.setGestureEnabled(true)
        actionsView?.removeFromSuperview()
        actionsView = nil
    }
    
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGestureRecognizer {
            if UIAccessibilityIsVoiceOverRunning() {
                tableView?.hideSwipeCell()
            }
            
            let cell = tableView?.swipeCells.first(where: { $0.state.isActive })
            return cell == nil ? false : true
        }
        
        if gestureRecognizer == panGestureRecognizer,
            let view = gestureRecognizer.view,
            let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer
        {
            let translation = gestureRecognizer.translation(in: view)
            return abs(translation.y) <= abs(translation.x)
        }
        
        return true
    }
    
    func swipeActionsView(_ swipeCellActionView: SwipeCellActionView, didSelect action: SwipeAction) {
        // delete action
        perform(action: action)
    }
    
    func perform(action: SwipeAction) {
        guard let tableView = tableView, let indexPath = tableView.indexPath(for: self) else { return }
        
        action.handler?(action, indexPath)
    }
}

extension UITableView {
    var swipeCells: [SwipeCellView] {
        return visibleCells.flatMap({ $0 as? SwipeCellView })
    }
    
    func hideSwipeCell() {
        swipeCells.forEach { $0.hideSwipe(animated: true) }
    }
    
    func setGestureEnabled(_ enabled: Bool) {
        gestureRecognizers?.forEach {
            guard $0 != panGestureRecognizer else { return }
            
            $0.isEnabled = enabled
        }
    }
}

extension UIPanGestureRecognizer {
    func elasticTranslation(in view: UIView?, withLimit limit: CGSize, fromOriginalCenter center: CGPoint, applyingRatio ratio: CGFloat = 0.0) -> CGPoint {
        let translation = self.translation(in: view)
        
        guard let sourceView = self.view else {
            return translation
        }
        
        let updatedCenter = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        let distanceFromCenter = CGSize(width: abs(updatedCenter.x - sourceView.bounds.midX),
                                        height: abs(updatedCenter.y - sourceView.bounds.midY))
        
        let inverseRatio = 1.0 - ratio
        let scale: (x: CGFloat, y: CGFloat) = (updatedCenter.x < sourceView.bounds.midX ? -1 : 1, updatedCenter.y < sourceView.bounds.midY ? -1 : 1)
        let x = updatedCenter.x - (distanceFromCenter.width > limit.width ? inverseRatio * (distanceFromCenter.width - limit.width) * scale.x : 0)
        let y = updatedCenter.y - (distanceFromCenter.height > limit.height ? inverseRatio * (distanceFromCenter.height - limit.height) * scale.y : 0)
        
        return CGPoint(x: x, y: y)
    }
}
