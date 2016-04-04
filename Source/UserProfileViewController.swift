//
//  UserProfileViewController.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class UserProfileViewController: UIViewController {
    
    public typealias Environment = protocol<OEXAnalyticsProvider, NetworkManagerProvider, OEXRouterProvider>
    
    private let environment : Environment
    
    private let profileFeed: Feed<UserProfile>
    private let editable: Bool

    private let loadController = LoadStateViewController()
    private let contentView = UserProfileView(frame: CGRectZero)
    
    public init(environment : Environment, feed: Feed<UserProfile>, editable: Bool = true) {
        self.editable = editable
        self.environment = environment
        self.profileFeed = feed
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addListener() {
        let editable = self.editable
        let networkManager = environment.networkManager
        profileFeed.output.listen(self, success: { [weak self] profile in
            self?.contentView.populateFields(profile, editable: editable, networkManager: networkManager)
            self?.loadController.state = .Loaded
            }, failure : { [weak self] error in
                self?.loadController.state = LoadState.failed(error, message: Strings.Profile.unableToGet)
        })
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(contentView)
        contentView.snp_makeConstraints {make in
            make.edges.equalTo(view)
        }
        
        if editable {
            let editButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: nil, action: nil)
            editButton.oex_setAction() { [weak self] in
                self?.environment.router?.showProfileEditorFromController(self!)
            }
            editButton.accessibilityLabel = Strings.Profile.editAccessibility
            navigationItem.rightBarButtonItem = editButton
        }

        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)

        addListener()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenProfileView)

        profileFeed.refresh()
    }

}

