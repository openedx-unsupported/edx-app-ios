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
    case Setting,
         Profile,
         SubmitFeedback,
         Logout
    
        static let options = [Setting, Profile, SubmitFeedback, Logout]
}

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let contentView = UIView()
    private let tableView = UITableView()
    private let versionView = UIView()
    private let versionLabel = UILabel()
    private var optionsArray : [String] = []
    public typealias Environment =  OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXRouterProvider
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

        self.navigationItem.title = "Account"
        self.view.backgroundColor = UIColor.white
        
        view.addSubview(contentView)
        contentView.addSubview(tableView)
        contentView.addSubview(versionView)
        versionView.addSubview(versionLabel)

        configureViews()
        populateOptionsArray()
    }
    
    
    func configureViews() {
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
        tableView.register(AccountViewCell.self, forCellReuseIdentifier: AccountViewCell.identifier)
        
        
        versionLabel.text = Strings.versionDisplay(number: Bundle.main.oex_buildVersionString(), environment: "")
        versionLabel.textAlignment = NSTextAlignment.center
        
        contentView.snp_makeConstraints {make in
            make.edges.equalTo(view)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(versionView.snp_top)
        }
        
        versionView.snp_makeConstraints { make -> Void in
            make.height.equalTo(50)
            make.top.equalTo(tableView.snp_bottom)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
        
        versionLabel.snp_makeConstraints { make -> Void in
            make.height.equalTo(versionView.snp_height)
            make.width.equalTo(versionView.snp_width)
            make.top.equalTo(versionView)
            make.leading.equalTo(versionView)
            make.trailing.equalTo(versionView)
            make.bottom.equalTo(versionView)
        }
    }
    
    func populateOptionsArray() {
        for option in AccountviewOptions.options {
            if let optionTitle = getOptionTitle(option: option) {
                optionsArray.append(optionTitle)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    public func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return AccountviewOptions.options.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountViewCell.identifier, for: indexPath) as! AccountViewCell
        cell.separatorInset = UIEdgeInsets.zero
        cell.configureView(withTitle: optionsArray[indexPath.row])
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let option = AccountviewOptions(rawValue: indexPath.row) {
            switch option {
            case .Setting:
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
    
    fileprivate func getOptionTitle(option: AccountviewOptions) -> String? {
        var optionTitle : String?
        switch option {
        case .Setting :
            optionTitle = Strings.settings
        case .Profile:
            guard environment.config.profilesEnabled else { break }
            optionTitle = Strings.profile
        case .SubmitFeedback:
            optionTitle = Strings.SubmitFeedback.optionTitle
        case .Logout:
            optionTitle = Strings.logout
        }
        
        return optionTitle
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
