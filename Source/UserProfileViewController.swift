//
//  UserProfileViewController.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class UserProfileViewController: OfflineSupportViewController, UserProfilePresenterDelegate, LoadStateViewReloadSupport {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & NetworkManagerProvider & OEXRouterProvider & ReachabilityProvider & OEXStylesProvider
    
    private let environment : Environment

    private let editable: Bool

    private let loadController = LoadStateViewController()
    fileprivate let contentView = UserProfileView(frame: CGRect.zero)
    private let presenter : UserProfilePresenter
    
    convenience init(environment : UserProfileNetworkPresenter.Environment & Environment, username : String, editable: Bool) {

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
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
        loadController.setupInController(controller: self, contentView: contentView)
        loadController.state = .Initial
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.plain, target: nil, action: nil)

        addProfileListener()
        addExtraTabsListener()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenProfileView)

        presenter.refresh()
    }
    
    private func addProfileEditButton() {
        if editable {
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil)
            editButton.oex_setAction() { [weak self] in
                if let owner = self {
                    owner.environment.router?.showProfileEditorFromController(controller: owner)
                }
            }
            editButton.accessibilityLabel = Strings.Profile.editAccessibility
            navigationItem.rightBarButtonItem = editButton
        }
    }
    
    private func removeProfileEditButton() {
        navigationItem.rightBarButtonItem = nil
    }
    
    override func reloadViewData() {
        presenter.refresh()
    }

    private func addProfileListener() {
        let editable = self.editable
        let networkManager = environment.networkManager
        presenter.profileStream.listen(self, success: { [weak self] profile in
            // TODO: Refactor UserProfileView to take a dumb model so we don't need to pass it a network manager
            self?.contentView.populateFields(profile: profile, editable: editable, networkManager: networkManager)
            self?.loadController.state = .Loaded
            self?.addProfileEditButton()
            }, failure : { [weak self] error in
                self?.loadController.state = LoadState.failed(error: error, message: Strings.Profile.unableToGet)
                self?.removeProfileEditButton()
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
        self.present(controller, animated: true, completion: nil)
    }
    
    //MARK:- LoadStateViewReloadSupport method
    func loadStateViewReload() {
        if !environment.reachability.isReachable() { return }
        
        loadController.state = .Initial
        presenter.refresh()
    }
}


extension UserProfileViewController {
    func t_chooseTab(identifier: String) {
        self.contentView.chooseTab(identifier: identifier)
    }
}
