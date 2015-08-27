//
//  PullRefreshController.swift
//  edX
//
//  Created by Akiva Leffert on 8/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let StandardRefreshHeight : CGFloat = 60

public class PullRefreshView : UIView {
    private let spinner = SpinnerView(size: .Large, color: .Primary)
    
    public init() {
        spinner.stopAnimating()
        super.init(frame : CGRectZero)
        addSubview(spinner)
        spinner.snp_makeConstraints {make in
            make.center.equalTo(self)
        }
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(UIViewNoIntrinsicMetric, StandardRefreshHeight)
    }
}

public protocol PullRefreshControllerDelegate : class {
    func refreshControllerActivated(controller : PullRefreshController)
}

public class PullRefreshController: NSObject, ContentInsetsSource {
    public weak var insetsDelegate : ContentInsetsSourceDelegate?
    public weak var delegate : PullRefreshControllerDelegate?
    private let view : PullRefreshView
    
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
    }
    
    private func triggered() {
        if !refreshing {
            refreshing = true
            self.insetsDelegate?.contentInsetsSourceChanged(self)
            self.delegate?.refreshControllerActivated(self)
            view.spinner.startAnimating()
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
    
    /// Call from your scroll view delegate's scrollViewDidScroll method
    public func scrollViewDidScroll(scrollView : UIScrollView) {
        if scrollView.bounds.minY < -view.frame.height {
            self.triggered()
        }
        // TODO: Drive an animation to indicate how far the user is from triggering it
    }
    
}
