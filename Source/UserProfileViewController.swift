//
//  UserProfileViewController.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class UserProfileViewController: OfflineSupportViewController, UserProfilePresenterDelegate, LoadStateViewReloadSupport, StatusBarOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & NetworkManagerProvider & OEXRouterProvider & ReachabilityProvider & OEXStylesProvider & OEXSessionProvider
    
    private let environment : Environment

    private let editable: Bool

    private let loadController = LoadStateViewController()
    fileprivate var contentView : UserProfileView
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
        self.contentView = UserProfileView(environment: self.environment, frame: CGRect.zero)
        super.init(env: environment)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        addBackBarButtonItem()
        view.backgroundColor = environment.styles.standardBackgroundColor()
        loadController.setupInController(controller: self, contentView: contentView)
        loadController.state = .Initial
        
        navigationItem.title = Strings.UserAccount.profile
        addProfileListener()
        addExtraTabsListener()
        addCloseButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenProfileView)
        navigationController?.navigationBar.applyUserProfileNavbarColorScheme()
        
        presenter.refresh()
    }
    
    private func addBackBarButtonItem() {
        let backItem = UIBarButtonItem(image: Icon.ArrowLeft.imageWithFontSize(size: 40), style: .plain, target: nil, action: nil)
        backItem.oex_setAction {[weak self] in
            // Profile has different navbar color scheme that's why we need to revert nav bar color to original color while poping the controller
            self?.navigationController?.navigationBar.applyDefaultNavbarColorScheme()
            self?.navigationController?.popViewController(animated: true)
        }
        navigationItem.leftBarButtonItem = backItem
    }
    
    private func addProfileEditButton() {
        if editable {
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil)
            editButton.oex_setAction() { [weak self] in
                if let owner = self {
                    owner.environment.router?.showProfileEditorFromController(controller: owner)
                }
                self?.navigationController?.navigationBar.applyDefaultNavbarColorScheme()
            }
            editButton.accessibilityLabel = Strings.Profile.editAccessibility
            navigationItem.rightBarButtonItem = editButton
        }
    }
    
    private func addCloseButton() {
        if (isModal()) {//isModal check if the view is presented then add close button
            let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
            closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
            closeButton.accessibilityHint = Strings.Accessibility.closeHint
            navigationItem.leftBarButtonItem = closeButton
            
            closeButton.oex_setAction { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
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
        if let titleView = navigationItem.titleView {
            // Badges are not enabled, so sourceView can be revised on enabling of badges as per position of share location
            // Position of UIActivityViewController can be not as per on iPad but app will not crash
            controller.configurePresentationController(withSourceView: titleView)
            present(controller, animated: true, completion: nil)
        }
    }
    
    //MARK:- LoadStateViewReloadSupport method
    func loadStateViewReload() {
        if !environment.reachability.isReachable() { return }
        
        loadController.state = .Initial
        presenter.refresh()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle(barStyle: .black)
    }
}


extension UserProfileViewController {
    func t_chooseTab(identifier: String) {
        self.contentView.chooseTab(identifier: identifier)
    }
}

extension UINavigationBar {
    // To update navbar color scheme on specific controllers 
    private func apply(barTintColor: UIColor, tintColor: UIColor, titleStyle: OEXTextStyle) {
        self.barTintColor = barTintColor
        self.tintColor = tintColor
        titleTextAttributes = titleStyle.attributes
    }
    
    func applyUserProfileNavbarColorScheme() {
        // Profile has different navbar color scheme that's why we need to update nav bar color for profile
        let neutralWhiteColor = OEXStyles.shared().neutralWhite()
        let titleStyle = OEXTextStyle(weight: .semiBold, size: .base, color : neutralWhiteColor)
        apply(barTintColor: OEXStyles.shared().primaryBaseColor(), tintColor: neutralWhiteColor, titleStyle: titleStyle)
    }
    
    func applyDefaultNavbarColorScheme() {
        apply(barTintColor: OEXStyles.shared().navigationBarColor(), tintColor: OEXStyles.shared().navigationItemTintColor(), titleStyle: OEXStyles.shared().navigationTitleTextStyle)
    }
}

