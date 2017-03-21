//
//  UserProfileViewController.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class UserProfileViewController: OfflineSupportViewController, UserProfilePresenterDelegate, LoadStateViewReloadSupport {
    
    typealias Environment = protocol<
        OEXAnalyticsProvider,
        OEXConfigProvider,
        NetworkManagerProvider,
        OEXRouterProvider,
        ReachabilityProvider
    >
    
    private let environment : Environment

    private let editable: Bool

    private let loadController = LoadStateViewController()
    private let contentView = UserProfileView(frame: CGRectZero)
    private let presenter : UserProfilePresenter
    
    convenience init(environment : protocol<UserProfileNetworkPresenter.Environment, Environment>, username : String, editable: Bool) {

        let presenter = UserProfileNetworkPresenter(environment: environment, username: username)
        self.init(environment: environment, presenter: presenter, editable: editable)
        presenter.delegate = self
    }

    init(environment: Environment, presenter: UserProfilePresenter, editable: Bool) {
        self.editable = editable
        self.environment = environment
        self.presenter = presenter
        super.init(env: environment)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
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

        addProfileListener()
        addExtraTabsListener()

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenProfileView)

        presenter.refresh()
    }
    
    override func reloadViewData() {
        presenter.refresh()
    }

    private func addProfileListener() {
        let editable = self.editable
        let networkManager = environment.networkManager
        presenter.profileStream.listen(self, success: { [weak self] profile in
            // TODO: Refactor UserProfileView to take a dumb model so we don't need to pass it a network manager
            self?.contentView.populateFields(profile, editable: editable, networkManager: networkManager)
            self?.loadController.state = .Loaded
            }, failure : { [weak self] error in
                self?.loadController.state = LoadState.failed(error, message: Strings.Profile.unableToGet)
            })
    }

    private func addExtraTabsListener() {
        presenter.tabStream.listen(self, success: {[weak self] in
            self?.contentView.extraTabs = $0
            }, failure: {_ in
                // ignore. Better to just not show tabs and still show the profile assuming the rest of it worked fine
            }
        )
    }

    func presenter(presenter: UserProfilePresenter, choseShareURL url: NSURL) {
        let message = Strings.Accomplishments.shareText(platformName:self.environment.config.platformName())
        let controller = UIActivityViewController(
            activityItems: [message, url],
            applicationActivities: nil
        )
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    //MARK:- LoadStateViewReloadSupport method
    func loadStateViewReload() {
        presenter.refresh()
    }
}


extension UserProfileViewController {
    func t_chooseTab(identifier: String) {
        self.contentView.chooseTab(identifier)
    }
}
