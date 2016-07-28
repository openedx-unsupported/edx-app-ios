//
//  OfflineSupportViewController.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

/// Convenient class for supporting an offline snackbar at the bottom of the controller
/// Override reloadViewData function

public class OfflineSupportViewController: UIViewController {
    typealias Env = protocol<ReachabilityProvider>
    private let environment : Env
    init(env: Env) {
        self.environment = env
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        showOfflineSnackBarIfNecessary()
    }
    
    private func setupObservers() {
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: kReachabilityChangedNotification) { (notification, observer, _) -> Void in
            observer.showOfflineSnackBarIfNecessary()
        }
    }
    
    private func showOfflineSnackBarIfNecessary() {
        if !environment.reachability.isReachable() {
            showOfflineSnackBar(Strings.offline, selector: #selector(reloadViewData))
        }
    }
    
    /// This function reload view data when internet is available and user hit reload
    /// Subclass must override this function
    func reloadViewData() {
        preconditionFailure("This method must be overridden by the subclass")
    }
}