//
//  AccountViewController.swift
//  edX
//
//  Created by Salman on 15/08/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import MessageUI

fileprivate enum AccountviewOptions : Int {
    case UserSettings,
         Profile,
         SubmitFeedback,
         Logout
    
        static let accountOptions = [UserSettings, Profile, SubmitFeedback, Logout]
}

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let contentView = UIView()
    private let tableView = UITableView()
    private let versionLabel = UILabel()
    private var accountViewOptionsArray : [String] = []
    private let textStyle = OEXMutableTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralBlack())
    private let titleStyle = OEXTextStyle(weight: .normal, size: .large, color : OEXStyles.shared().neutralBlack())
    typealias Environment =  OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider
    fileprivate let environment: Environment
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle :nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = Strings.userAccount
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        view.addSubview(contentView)
        contentView.addSubview(tableView)
        contentView.addSubview(versionLabel)

        configureViews()
        populateOptions()
    }
    
    func configureViews() {
        tableView.estimatedRowHeight = 400
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.register(AccountViewCell.self, forCellReuseIdentifier: AccountViewCell.identifier)
    
        textStyle.alignment = NSTextAlignment.center
        versionLabel.attributedText = textStyle.attributedString(withText: Strings.versionDisplay(number: Bundle.main.oex_buildVersionString(), environment: ""))
        
        contentView.snp_makeConstraints {make in
            make.edges.equalTo(view)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(versionLabel.snp_top)
        }
        
        versionLabel.snp_makeConstraints { make -> Void in
            make.width.equalTo(contentView.snp_width)
            make.top.equalTo(tableView.snp_bottom)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView).inset(20)
        }
    }
    
    func populateOptions() {
        for option in AccountviewOptions.accountOptions {
            if let title = optionTitle(option: option) {
                accountViewOptionsArray.append(title)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accountViewOptionsArray.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewCell.identifier, for: indexPath) as! AccountViewCell
        cell.separatorInset = UIEdgeInsets.zero
        cell.titleLabel.attributedText = titleStyle.attributedString(withText: accountViewOptionsArray[indexPath.row])
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let option = AccountviewOptions(rawValue: indexPath.row) {
            switch option {
            case .UserSettings:
                environment.router?.showMySettings(controller: self)
            case .Profile:
                guard environment.config.profilesEnabled else { break }
                guard let currentUserName = environment.session.currentUser?.username else { return }
                environment.router?.showProfileForUsername(controller: self, username: currentUserName, editable: true)
            case .SubmitFeedback:
                launchEmailComposer()
            case .Logout:
                OEXFileUtility.nukeUserPIIData()
                environment.router?.logout()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    fileprivate func optionTitle(option: AccountviewOptions) -> String? {
        var title : String?
        switch option {
        case .UserSettings :
            title = Strings.settings
        case .Profile:
            guard environment.config.profilesEnabled else { break }
            title = Strings.UserAccount.profile
        case .SubmitFeedback:
            title = Strings.SubmitFeedback.optionTitle
        case .Logout:
            title = Strings.logout
        }
        
        return title
    }
}

extension AccountViewController : MFMailComposeViewControllerDelegate {
    func launchEmailComposer() {
        if !MFMailComposeViewController.canSendMail() {
            let alert = UIAlertView(title: Strings.emailAccountNotSetUpTitle,
                                    message: Strings.emailAccountNotSetUpMessage,
                                    delegate: nil,
                                    cancelButtonTitle: Strings.ok)
            alert.show()
        } else {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.navigationBar.tintColor = OEXStyles.shared().navigationItemTintColor()
            mail.setSubject(Strings.SubmitFeedback.messageSubject)
            
            mail.setMessageBody(EmailTemplates.supportEmailMessageTemplate(), isHTML: false)
            if let fbAddress = environment.config.feedbackEmailAddress() {
                mail.setToRecipients([fbAddress])
            }
            present(mail, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
