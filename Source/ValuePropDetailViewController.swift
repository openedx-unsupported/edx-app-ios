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

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(ValuePropMessageCell.self, forCellReuseIdentifier: ValuePropMessageCell.identifier)
        tableView.accessibilityIdentifier = "ValuePropDetailView:tableView"
        return tableView
    }()
    
    private var titleStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .normal, size: .xxxLarge, color: OEXStyles.shared().primaryBaseColor())
        style.alignment = .center
        return style
    }()
    
    private var type: ValuePropModalType
    private var course: OEXCourse
    private let rowHeaderHeight:CGFloat = 260
    private let messageOptions = [Strings.UpgradeCourseValueProp.detailViewMessagePointOne, Strings.UpgradeCourseValueProp.detailViewMessagePointTwo, Strings.UpgradeCourseValueProp.detailViewMessagePointThree, Strings.UpgradeCourseValueProp.detailViewMessagePointFour]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        screenAnalytics()
        configureView()
    }
    
    init(type: ValuePropModalType, course: OEXCourse) {
        self.type = type
        self.course = course
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func screenAnalytics() {
        let screenName = type == .courseEnrollment ? AnalyticsScreenName.ValuePropModalForCourseEnrollment : AnalyticsScreenName.ValuePropModalForCourseUnit
        OEXAnalytics.shared().trackValueProModal(withName: screenName, courseId: course.course_id ?? "", userID: OEXSession.shared()?.currentUser?.userId?.intValue ?? 0)
    }
    
    private func configureView() {
        addViews()
        setUpConstraint()
    }
    
    private func addViews() {
        view.addSubview(tableView)
        addCloseButton()
    }
    
    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: 30), style: .plain, target: nil, action: nil)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "ValuePropDetailView:close-button"
        navigationItem.rightBarButtonItem = closeButton
        
        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func setUpConstraint() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    func createHeader() -> UIView {
        let titleLabel: UILabel = {
           let title = UILabel()
            title.numberOfLines = 0
            title.accessibilityIdentifier = "ValuePropDetailView:title-label"
            return title
        }()
        
        let messageTitleLabel: UILabel = {
            let label = UILabel()
            label.attributedText = titleStyle.attributedString(withText: Strings.UpgradeCourseValueProp.detailViewMessageHeading)
            label.accessibilityIdentifier = "ValuePropDetailView:message-title-label"
            return label
        }()
        
        let certificateImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "courseCertificate.png")
            imageView.accessibilityIdentifier = "ValuePropDetailView:certificate-image"
            return imageView
        }()
        
        let title = type == .courseEnrollment ? Strings.UpgradeCourseValueProp.detailViewTitle : ""
        titleLabel.attributedText = titleStyle.attributedString(withText: title)
        
        let headerView = UIView(frame: CGRect.zero)
        headerView.accessibilityIdentifier = "ValuePropDetailView:header-view"
        headerView.addSubview(titleLabel)
        headerView.addSubview(certificateImageView)
        headerView.addSubview(messageTitleLabel)
    
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(StandardVerticalMargin*4)
            make.centerX.equalTo(headerView)
            make.leading.equalTo(headerView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(headerView).inset(StandardHorizontalMargin)
        }
        
        certificateImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin*4)
            make.centerX.equalTo(headerView)
        }
        
        messageTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(certificateImageView.snp.bottom).offset(StandardVerticalMargin*4)
            make.leading.equalTo(headerView).offset(StandardHorizontalMargin)
        }

        return headerView
    }
}

extension ValuePropDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return createHeader()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return rowHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ValuePropMessageCell.identifier, for: indexPath) as! ValuePropMessageCell
        cell.setMessage(message: messageOptions[indexPath.row])
        return cell
    }
}

class ValuePropMessageCell: UITableViewCell {
    static let identifier = "ValuePropMessageCell"
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    private lazy var bulletImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.CheckCircleO.imageWithFontSize(size: 28)
        return imageView
    }()
    private lazy var messageContainer = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addViews() {
        contentView.addSubview(messageContainer)
        messageContainer.addSubview(messageLabel)
        messageContainer.addSubview(bulletImage)
        setUpConstraints()
    }
    
    func setMessage(message: String) {
        let messageStyle = OEXMutableTextStyle(weight: .light, size: .large, color: OEXStyles.shared().primaryDarkColor())
        messageLabel.attributedText = messageStyle.attributedString(withText: message)
    }
    
    private func setUpIdentifiers() {
        messageContainer.accessibilityIdentifier = "ValuePropDetailView:message-container"
        bulletImage.accessibilityIdentifier = "ValuePropDetailView:bullet-image"
        bulletImage.accessibilityIdentifier = "ValuePropDetailView:message-label"
    }
    
    private func setUpConstraints() {
        messageContainer.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }

        bulletImage.snp.makeConstraints { make in
            make.top.equalTo(messageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(messageContainer).offset(StandardVerticalMargin)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(messageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(bulletImage.snp.trailing).offset(StandardVerticalMargin)
            make.trailing.equalTo(messageContainer)
            make.bottom.equalTo(messageContainer).inset(StandardVerticalMargin)
        }
    }
}
