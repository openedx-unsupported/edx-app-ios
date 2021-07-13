//
//  ValuePropDetailViewController.swift
//  edX
//
//  Created by Salman on 19/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

enum ValuePropModalType {
    case courseEnrollment
    case courseUnit
}

class ValuePropDetailViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXStylesProvider
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
        tableView.register(ValuePropMessageCell.self, forCellReuseIdentifier: ValuePropMessageCell.identifier)
        tableView.accessibilityIdentifier = "ValuePropDetailView:tableView"
        return tableView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = titleStyle.attributedString(withText: Strings.ValueProp.upgrade(courseName: course.name ?? ""))
        return label
    }()
    
    private lazy var buttonUpgradeNow: UIButton = {
        let button = UIButton()
        button.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        let buttonTitle = Strings.ValueProp.upgradeNowFor(price: "99")
        
        let lockedImage = Icon.Closed.imageWithFontSize(size: 16).image(with: environment.styles.neutralWhiteT())
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = lockedImage
        let imageOffsetY: CGFloat = -2.0
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: image.size.width, height: image.size.height)
        }
        
        let attributedImageString = NSAttributedString(attachment: imageAttachment)
        let style = OEXTextStyle(weight : .normal, size: .base, color: environment.styles.neutralWhiteT())
        let attributedStrings = [
            attributedImageString,
            NSAttributedString(string: "\u{2000}"),
            style.attributedString(withText: buttonTitle)
        ]
        let buttonAttributedTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
        button.setAttributedTitle(buttonAttributedTitle, for: .normal)
        button.contentVerticalAlignment = .center
        
        return button
    }()
    
    private var titleStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .xxLarge, color: OEXStyles.shared().primaryBaseColor())
        style.alignment = .left
        return style
    }()
    
    private let crossButtonSize: CGFloat = 20
    
    private let infoMessages = [
        Strings.ValueProp.infoMessage1,
        Strings.ValueProp.infoMessage2,
        Strings.ValueProp.infoMessage3,
        Strings.ValueProp.infoMessage4(platformName: OEXConfig.shared().platformName())
    ]
    
    private var type: ValuePropModalType
    private let course: OEXCourse
    private let environment: Environment
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
        configureView()
    }
    
    init(type: ValuePropModalType, course: OEXCourse, environment: Environment) {
        self.type = type
        self.course = course
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        addSubviews()
        setConstraints()
    }
    
    private func addSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(buttonUpgradeNow)
        addCloseButton()
    }
    
    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: crossButtonSize), style: .plain, target: nil, action: nil)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "ValuePropDetailView:close-button"
        navigationItem.rightBarButtonItem = closeButton
        
        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func setConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(view).inset(StandardHorizontalMargin * 2)
            make.top.equalTo(view).offset(StandardVerticalMargin)
        }
        
        tableView.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(StandardHorizontalMargin * 1.5)
            make.trailing.equalTo(view).inset(StandardHorizontalMargin * 2)
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(buttonUpgradeNow.snp.top).inset(StandardVerticalMargin)
        }
        
        buttonUpgradeNow.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(view).inset(StandardHorizontalMargin * 2)
            make.bottom.equalTo(safeBottom).inset(StandardVerticalMargin)
            make.height.equalTo(36)
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

extension ValuePropDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ValuePropMessageCell.identifier, for: indexPath) as! ValuePropMessageCell
        cell.setMessage(message: infoMessages[indexPath.row])
        cell.backgroundColor = .clear
        return cell
    }
}

private class ValuePropMessageCell: UITableViewCell {
    static let identifier = "ValuePropMessageCell"
    private let bulletImageSize: CGFloat = 27
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var bulletImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.Check.imageWithFontSize(size: 26).image(with: OEXStyles.shared().successBase())
        imageView.backgroundColor = OEXStyles.shared().successXXLight()
        return imageView
    }()
    
    private lazy var containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
        setAccessibilityIdentifiers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bulletImage.layoutIfNeeded()
        bulletImage.clipsToBounds = true
        bulletImage.layer.cornerRadius = bulletImage.frame.size.width * 0.50
    }
    
    private func addSubviews() {
        contentView.addSubview(containerView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(bulletImage)
        setConstraints()
    }
    
    func setMessage(message: String) {
        let messageStyle = OEXMutableTextStyle(weight: .normal, size: .large, color: OEXStyles.shared().primaryDarkColor())
        messageLabel.attributedText = messageStyle.attributedString(withText: message)
    }
    
    private func setAccessibilityIdentifiers() {
        containerView.accessibilityIdentifier = "ValuePropMessageCell:container-view"
        bulletImage.accessibilityIdentifier = "ValuePropMessageCell:bullet-image"
        bulletImage.accessibilityIdentifier = "ValuePropMessageCell:message-label"
    }
    
    private func setConstraints() {
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
        
        bulletImage.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.leading.equalTo(containerView).offset(StandardVerticalMargin)
            make.width.equalTo(bulletImageSize)
            make.height.equalTo(bulletImageSize)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.leading.equalTo(bulletImage.snp.trailing).offset(StandardVerticalMargin)
            make.trailing.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(StandardVerticalMargin)
        }
    }
}
