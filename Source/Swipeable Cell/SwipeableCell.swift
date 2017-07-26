//
//  SwipeableCell.swift
//  edX
//
//  Created by Salman on 19/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

protocol SwipeableCellDelegate: class {
    
    // The delegate for the actions to display in response to a swipe in the specified row.
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeActionButton]?
    
}

class SwipeableCell: UITableViewCell {
    
    /// The object that acts as the delegate of the `SwipeableCell`.
    public weak var swipeCellViewDelegate: SwipeableCellDelegate?
    private var animator: SwipeAnimator?
    private var originalCenter: CGFloat = 0
    fileprivate weak var tableView: UITableView?
    fileprivate var actionsView: SwipeCellActionView?
    private var originalLayoutMargins: UIEdgeInsets = .zero
    fileprivate var panGestureRecognizer = UIPanGestureRecognizer()
    fileprivate var tapGestureRecognizer = UITapGestureRecognizer()
    var state = SwipeState.initial
    
    override var center: CGPoint {
        didSet {
            actionsView?.visibleWidth = abs(frame.minX)
        }
    }
    
    override var frame: CGRect {
        set { super.frame = state.isActive ? CGRect(origin: CGPoint(x: frame.minX, y: newValue.minY), size: newValue.size) : newValue }
        get { return super.frame }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configure()
    }
    
    deinit {
        tableView?.panGestureRecognizer.removeTarget(self, action: nil)
    }
    
    private func configure() {
        clipsToBounds = false
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(panGestureRecognizer)
    }
    
    override func didMoveToSuperview() {
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
    
    private func isRTL() -> Bool {
        return (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft)
    }
    
    private func allowedDirection(ForVelocity velocity: CGPoint) -> Bool {
        var swipAllowed = false
        if((isRTL() && velocity.x > 0) || (!isRTL() && velocity.x < 0)) {
            swipAllowed = true
        }
        else if ((velocity.x > 0 && state == .right) || ((velocity.x < 0 && state == .left))) {
            hideSwipe(animated: true)
            swipAllowed = false
        }
        return swipAllowed
    }
    
    private func handlePan(gesture: UIPanGestureRecognizer) {
        guard let target = gesture.view, allowedDirection(ForVelocity: gesture.velocity(in: target)) else { return }
        
        switch gesture.state {
        case .began:
            stopAnimatorIfNeeded()
            originalCenter = center.x
            if state == .initial || state == .animatingToInitial {
                let velocity = gesture.velocity(in: target)
                let orientation: SwipeActionsOrientation = velocity.x > 0 ? .left : .right
                showActionsView(for: orientation)
                state = targetState(forVelocity: velocity)
                
            }
        case .changed:
            let velocity = gesture.velocity(in: target)
            state = targetState(forVelocity: velocity)
            let targetOffset = targetCenter(active: state.isActive)
            let distance = targetOffset - center.x
            let normalizedVelocity = velocity.x * 1.0 / distance
            animate(toOffset: targetOffset, withInitialVelocity: normalizedVelocity) {[weak self] _ in
                if self?.state == .initial {
                    self?.reset()
                }
            }
            
        default: break
        }
    }
    
    func hideSwipe(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        state = .animatingToInitial
        tableView?.setGestureEnabled(true)
        let targetCenter = self.targetCenter(active: false)
        if animated {
            animate(toOffset: targetCenter) {[weak self] complete in
                self?.reset()
                completion?(complete)
            }
        } else {
            center = CGPoint(x: targetCenter, y: self.center.y)
            reset()
        }
    }
    
    @discardableResult
    private func showActionsView(for orientation: SwipeActionsOrientation) -> Bool {
        guard let tableView = tableView,
            let indexPath = tableView.indexPath(for: self),
            let actionButtons = swipeCellViewDelegate?.tableView(tableView, editActionsForRowAt: indexPath, for: orientation),
            actionButtons.count > 0
            else {
                return false
        }
        originalLayoutMargins = super.layoutMargins
        
        // Remove highlight and deselect any selected cells
        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        selectedIndexPaths?.forEach { tableView.deselectRow(at: $0, animated: false) }
        
        // Temporarily remove table gestures
        tableView.setGestureEnabled(false)
        configureActionsView(with: actionButtons, for: orientation)
        return true
    }
    
    private func configureActionsView(with actionButtons: [SwipeActionButton], for orientation: SwipeActionsOrientation) {
        
        self.actionsView?.removeFromSuperview()
        self.actionsView = nil
        let actionsView = SwipeCellActionView(maxSize: bounds.size, orientation: orientation, actions: actionButtons)
        actionsView.delegate = self
        addSubview(actionsView)
        actionsView.snp_makeConstraints(closure: { (make) in
            make.height.equalTo(self)
            make.width.equalTo(100)
            make.centerY.equalTo(self)
            make.leading.equalTo(snp_trailing)
        })
        self.actionsView = actionsView
    }
    
    private func animate(duration: Double = 0.7, toOffset offset: CGFloat, withInitialVelocity velocity: CGFloat = 0, completion: ((Bool) -> Void)? = nil) {
        stopAnimatorIfNeeded()
        layoutIfNeeded()
        let animator: SwipeAnimator = {
            if velocity != 0 {
                return UIViewSpringAnimator(duration: duration, damping: 1.0, initialVelocity: velocity)
            } else {
                return UIViewSpringAnimator(duration: duration, damping: 1.0)
            }
        }()
        
        animator.addAnimations({[weak self] _ in
            if let owner = self {
                owner.center = CGPoint(x: offset, y: owner.center.y)
                owner.layoutIfNeeded()
            }
        })
        
        if let completion = completion {
            animator.addCompletion(completion: completion)
        }
        
        self.animator = animator
        
        animator.startAnimation()
    }
    
    private func stopAnimatorIfNeeded() {
        if animator?.isRunning == true {
            animator?.stopAnimation(true)
        }
    }
    
    private func handleTap(gesture: UITapGestureRecognizer) {
        hideSwipe(animated: true);
    }
    
    func handleTablePan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            hideSwipe(animated: true)
        }
    }
    
    // Override so we can accept touches anywhere within the cell's minY/maxY.
    // This is required to detect touches on the `SwipeCellActionView` sitting alongside the
    // `SwipeableCell`.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
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
    
    private func contains(point: CGPoint) -> Bool {
        return point.y > frame.minY && point.y < frame.maxY
    }
    
    override var layoutMargins: UIEdgeInsets {
        get {
            return frame.origin.x != 0 ? originalLayoutMargins : super.layoutMargins
        }
        set {
            super.layoutMargins = newValue
        }
    }
}

extension SwipeableCell: SwipeActionsViewDelegate {
    fileprivate func targetState(forVelocity velocity: CGPoint) -> SwipeState {
        guard let actionsView = actionsView else { return .initial }
        
        switch actionsView.orientation {
        case .left:
            return (velocity.x < 0 && !actionsView.expanded) ? .initial : .left
        case .right:
            return (velocity.x > 0 && !actionsView.expanded) ? .initial : .right
        }
    }
    
    fileprivate func targetCenter(active: Bool) -> CGFloat {
        guard let actionsView = actionsView, active == true else { return bounds.midX }
        
        return bounds.midX - actionsView.preferredWidth * actionsView.orientation.scale
    }
    
    func reset() {
        state = .initial
        tableView?.setGestureEnabled(true)
        actionsView?.removeFromSuperview()
        actionsView = nil
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
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
    
    func swipeActionsView(_ swipeCellActionView: SwipeCellActionView, didSelect action: SwipeActionButton) {
        // delete action
        perform(action: action)
    }
    
    func perform(action: SwipeActionButton) {
        guard let tableView = tableView, let indexPath = tableView.indexPath(for: self) else { return }
        
        hideSwipe(animated: true)
        action.handler?(action, indexPath)
    }
}

extension UITableView {
    var swipeCells: [SwipeableCell] {
        return visibleCells.flatMap({ $0 as? SwipeableCell })
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
