//
//  PullRefreshController.swift
//  edX
//
//  Created by Akiva Leffert on 8/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let StandardRefreshHeight : CGFloat = 80

public class PullRefreshView : UIView {
    private let spinner = SpinnerView(size: .Large, color: .Primary)
    
    public init() {
        spinner.stopAnimating()
        super.init(frame : CGRectZero)
        addSubview(spinner)
        spinner.snp_makeConstraints {make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(10)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(UIViewNoIntrinsicMetric, StandardRefreshHeight)
    }
    
    public var percentage : CGFloat = 1 {
        didSet {
            let totalAngle = CGFloat(2 * M_PI * 2) // two full rotations
            let scale = (percentage * 0.9) + 0.1 // don't start from 0 scale because it looks weird
            spinner.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(percentage * totalAngle), CGAffineTransformMakeScale(scale, scale))
        }
    }
}

public protocol PullRefreshControllerDelegate : class {
    func refreshControllerActivated(controller : PullRefreshController)
}

public class PullRefreshController: NSObject, ContentInsetsSource {
    public weak var insetsDelegate : ContentInsetsSourceDelegate?
    public weak var delegate : PullRefreshControllerDelegate?
    private let view : PullRefreshView
    private var shouldStartOnTouchRelease : Bool = false
    
    private(set) var refreshing : Bool = false
    
    public override init() {
        view = PullRefreshView()
        super.init()
    }
    
    public func setupInScrollView(scrollView : UIScrollView) {
        scrollView.addSubview(self.view)
        self.view.snp_makeConstraints {make in
            make.bottom.equalTo(scrollView.snp_top)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        scrollView.oex_addObserver(self, forKeyPath: "bounds") { (observer, scrollView, _) -> Void in
            observer.scrollViewDidScroll(scrollView)
        }
    }
    
    private func triggered() {
        if !refreshing {
            refreshing = true
            view.spinner.startAnimating()
            self.insetsDelegate?.contentInsetsSourceChanged(self)
            self.delegate?.refreshControllerActivated(self)
        }
    }
    
    public var affectsScrollIndicators : Bool {
        return false
    }
    
    public func endRefreshing() {
        refreshing = false
        UIView.animateWithDuration(0.3) {
            self.insetsDelegate?.contentInsetsSourceChanged(self)
        }
        view.spinner.stopAnimating()
    }
    
    public var currentInsets : UIEdgeInsets {
        return UIEdgeInsetsMake(refreshing ? view.frame.height : 0, 0, 0, 0)
    }
    
    public func scrollViewDidScroll(scrollView : UIScrollView) {
        let pct = max(0, min(1, -scrollView.bounds.minY / view.frame.height))
        if !refreshing && scrollView.dragging {
            self.view.percentage = pct
        }
        else {
            self.view.percentage = 1
        }
        if pct >= 1 && scrollView.dragging {
            shouldStartOnTouchRelease = true
        }
        if shouldStartOnTouchRelease && !scrollView.dragging {
            triggered()
            shouldStartOnTouchRelease = false
        }
        // TODO: Drive an animation to indicate how far the user is from triggering it
    }
    
}
