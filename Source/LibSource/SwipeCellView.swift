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
    var state = SwipeState.initialPosition
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
    
    func isRTL() -> Bool {
        return (UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft)
    }
    
    func allowedDirection(ForVelocity velocity: CGPoint) -> Bool {
        var swipAllowed = false
        if(isRTL() && velocity.x > 0) {
            swipAllowed = true
        }
        else if(!isRTL() && velocity.x < 0) {
            swipAllowed = true
        }
        else if (velocity.x > 0 && state == .right) {
            hideSwipe(animated: true)
            swipAllowed = false
        }
        else if(velocity.x < 0 && state == .left) {
            hideSwipe(animated: true)
            swipAllowed = false
        }
        
        return swipAllowed
    }
    
    func handlePan(gesture: UIPanGestureRecognizer) {
        guard let target = gesture.view, allowedDirection(ForVelocity: gesture.velocity(in: target)) else { return }
        
        switch gesture.state {
            case .began:
                stopAnimatorIfNeeded()
                originalCenter = center.x
                if state == .initialPosition || state == .animatingToInitialPosition {
                    let velocity = gesture.velocity(in: target)
                    let orientation: SwipeActionsOrientation = velocity.x > 0 ? .left : .right
                    showActionsView(for: orientation)
                    state = targetState(forVelocity: velocity)
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
                    if self.state == .initialPosition {
                        self.reset()
                    }
                }
            default: break
        }
    }
    
    func hideSwipe(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        state = .animatingToInitialPosition
        tableView?.setGestureEnabled(true)
        let targetCenter = self.targetCenter(active: false)
        if animated {
            animate(toOffset: targetCenter) { complete in
                self.reset()
                completion?(complete)
                guard let tableView = self.tableView, let indexPath = tableView.indexPath(for: self) else {return}
                self.swipeCellViewDelegate?.tableView(tableView, swipActionEndForRowAt: indexPath)
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
        actionsView.snp_makeConstraints(closure: { (make) in
            make.height.equalTo(self)
            make.width.equalTo(100)
            make.centerY.equalTo(self)
            make.leading.equalTo(self.snp_trailing)
        })
        self.actionsView = actionsView
    }
    
    func animate(duration: Double = 0.7, toOffset offset: CGFloat, withInitialVelocity velocity: CGFloat = 0, completion: ((Bool) -> Void)? = nil) {
        stopAnimatorIfNeeded()
        layoutIfNeeded()
        let animator: SwipeAnimator = {
            if velocity != 0 {
                return UIViewSpringAnimator(duration: duration, damping: 1.0, initialVelocity: velocity)
            } else {
                return UIViewSpringAnimator(duration: duration, damping: 1.0)
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
        hideSwipe(animated: true);
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

        for cell in tableView?.swipeCells ?? [] {
            if (cell.state == .left || cell.state == .right) && !cell.contains(point: point) {
                tableView?.hideSwipeCell()
                return false
            }
        }
        
        return contains(point: point)
    }
    
    func contains(point: CGPoint) -> Bool {
        return point.y > frame.minY && point.y < frame.maxY
    }
    
    override open func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if state == .initialPosition {
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
        guard let actionsView = actionsView else { return .initialPosition }
        
        switch actionsView.orientation {
        case .left:
            return (velocity.x < 0 && !actionsView.expanded) ? .initialPosition : .left
        case .right:
            return (velocity.x > 0 && !actionsView.expanded) ? .initialPosition : .right
        }
    }
    
    func targetCenter(active: Bool) -> CGFloat {
        guard let actionsView = actionsView, active == true else { return bounds.midX }
        
        return bounds.midX - actionsView.preferredWidth * actionsView.orientation.scale
    }
    
    func reset() {
        state = .initialPosition
        tableView?.setGestureEnabled(true)
        actionsView?.removeFromSuperview()
        actionsView = nil
    }
    
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGestureRecognizer {
            
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
        
        hideSwipe(animated: true)
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
