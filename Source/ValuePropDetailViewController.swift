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

class ValuePropDetailViewController: UIViewController {
    
    typealias Environment = OEXAnalyticsProvider & OEXStylesProvider
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(ValuePropMessageCell.self, forCellReuseIdentifier: ValuePropMessageCell.identifier)
        tableView.register(ValuePropDetailHeaderView.self, forHeaderFooterViewReuseIdentifier: ValuePropDetailHeaderView.identifier)
        tableView.accessibilityIdentifier = "ValuePropDetailView:tableView"
        return tableView
    }()
    
    private var titleStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .normal, size: .xxxLarge, color: OEXStyles.shared().primaryBaseColor())
        style.alignment = .center
        return style
    }()
    private var messageTitleStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .normal, size: .xxLarge, color: OEXStyles.shared().primaryBaseColor())
        style.alignment = .center
        return style
    }()
    private let crossButtonSize: CGFloat = 20
    private var type: ValuePropModalType
    private var course: OEXCourse
    private let environment: Environment
    private let infoMessages = [Strings.ValueProp.infoMessage1, Strings.ValueProp.infoMessage2, Strings.ValueProp.infoMessage3, Strings.ValueProp.infoMessage4(platformName: OEXConfig.shared().platformName())]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
        logScreenEvent()
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
    
    private func logScreenEvent() {
        let screenName = type == .courseEnrollment ? AnalyticsScreenName.ValuePropModalForCourseEnrollment : AnalyticsScreenName.ValuePropModalForCourseUnit
        environment.analytics.trackValueProModal(withName: screenName, courseId: course.course_id ?? "")
    }
    
    private func configureView() {
        addSubviews()
        setConstraints()
    }
    
    private func addSubviews() {
        view.addSubview(tableView)
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
        tableView.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(StandardVerticalMargin * 2)
            make.top.equalTo(view)
            make.trailing.equalTo(view).inset(StandardVerticalMargin * 2)
            make.bottom.equalTo(view)
        }
    }
}

extension ValuePropDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: ValuePropDetailHeaderView.identifier) as! ValuePropDetailHeaderView
        let title = type == .courseEnrollment ? Strings.ValueProp.detailViewTitle : Strings.ValueProp.detailViewTitleLearnMore
        header.titleLabel.attributedText = titleStyle.attributedString(withText: title)
        header.messageTitleLabel.attributedText = messageTitleStyle.attributedString(withText: Strings.ValueProp.detailViewMessageTitle)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
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
    private let bulletImageSize: CGFloat = 20
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    private lazy var bulletImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.CheckCircleO.imageWithFontSize(size: bulletImageSize)
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

private class ValuePropDetailHeaderView : UITableViewHeaderFooterView {
    static let identifier = "ValuePropMessageHeaderCellIdentifier"
    
    lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.numberOfLines = 0
        return title
    }()
    
    lazy var messageTitleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    lazy var certificateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "courseCertificate")
        return imageView
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubviews()
        setConstraints()
        setAccessibilityIdentifiers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews(){
        addSubview(titleLabel)
        addSubview(messageTitleLabel)
        addSubview(certificateImageView)
    }
    
    private func setConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin*4)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        certificateImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin*4)
            make.centerX.equalTo(self)
        }
        
        messageTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(certificateImageView.snp.bottom).offset(StandardVerticalMargin*4)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.bottom.equalTo(self).inset(StandardVerticalMargin*2)
        }
    }
    
    private func setAccessibilityIdentifiers() {
        titleLabel.accessibilityIdentifier = "ValuePropDetailHeaderView:title-label"
        messageTitleLabel.accessibilityIdentifier = "ValuePropDetailHeaderView:message-title-label"
        certificateImageView.accessibilityIdentifier = "ValuePropDetailHeaderView:certificate-image"
    }
}
