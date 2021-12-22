//
//  ValuePropMessageView.swift
//  edX
//
//  Created by Muhammad Umer on 08/12/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

protocol ValuePropMessageViewDelegate: AnyObject {
    func showValuePropDetailView()
    func didTapUpgradeCourse(upgradeView: ValuePropComponentView)
}

class ValuePropComponentView: UIView {
    
    typealias Environment = OEXStylesProvider & DataManagerProvider & OEXAnalyticsProvider
        
    weak var delegate: ValuePropMessageViewDelegate?
        
    private let imageSize: CGFloat = 20
    
    private lazy var container = UIView()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var upgradeButton: CourseUpgradeButtonView = {
        let upgradeButton = CourseUpgradeButtonView()
        upgradeButton.tapAction = { [weak self] in
            self?.upgradeCourse()
        }
        return upgradeButton
    }()
    
    private var showingMore: Bool = false

    private lazy var showMoreLessButton: UIButton = {
       let button = UIButton()
        button.setAttributedTitle(showMorelessButtonStyle.attributedString(withText: Strings.ValueProp.showMoreText).addUnderline(), for: .normal)
        button.oex_addAction({[weak self] (action) in
            self?.toggleInfoMessagesView()
        }, for: .touchUpInside)
        return button
    }()

    private let infoMessagesView = ValuePropMessagesView()

    private lazy var lockImageView = UIImageView()
    
    private lazy var titleStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .bold, size: .small, color: environment.styles.neutralBlackT())
    }()
    
    private lazy var messageStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .normal, size: .base, color: environment.styles.neutralXXDark())
    }()

    private lazy var showMorelessButtonStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .normal, size: .small, color: environment.styles.neutralXXDark())
    }()

    private lazy var course: OEXCourse? = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.course
    
    private lazy var pacing: String = {
        let selfPaced = course?.isSelfPaced ?? false
        return selfPaced ? "self" : "instructor"
    }()

    private let environment: Environment
    private var courseID: String
    private var blockID: String

    init(environment: Environment, courseID: String, blockID: CourseBlockID?) {
        self.environment = environment
        self.courseID = courseID
        self.blockID = blockID ?? ""
        super.init(frame: .zero)
        
        setupViews()
        setConstraints()
        setAccessibilityIdentifiers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        container.addShadow(offset: CGSize(width: 0, height: 2), color: OEXStyles.shared().primaryDarkColor(), radius: 2, opacity: 0.35, cornerRadius: 5)
    }

    private func setupViews() {
        container.backgroundColor = environment.styles.neutralWhiteT()

        lockImageView.image = Icon.Closed.imageWithFontSize(size: imageSize).image(with: environment.styles.neutralBlackT())
        titleLabel.attributedText = titleStyle.attributedString(withText: Strings.ValueProp.assignmentsAreLocked)
        let attributedMessage = messageStyle.attributedString(withText: Strings.ValueProp.upgradeToAccessGraded)
        messageLabel.attributedText = attributedMessage.setLineSpacing(8)

        container.addSubview(titleLabel)
        container.addSubview(messageLabel)
        container.addSubview(lockImageView)
        container.addSubview(showMoreLessButton)
        container.addSubview(infoMessagesView)
        container.addSubview(upgradeButton)
        addSubview(container)
        
        guard let course = course, let courseSku = UpgradeSKUManager.shared.purchaseID(for: course) else { return }
        PaymentManager.shared.productPrice(courseSku) { [weak self] price in
            if let price = price {
                self?.upgradeButton.setPrice(price)
            }
        }
    }
    
    private func setConstraints() {
        container.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
            make.bottom.equalTo(upgradeButton).offset(StandardVerticalMargin * 2)
        }
        
        lockImageView.snp.makeConstraints { make in
            make.top.equalTo(StandardVerticalMargin * 2)
            make.leading.equalTo(container).offset(StandardHorizontalMargin + 3)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(lockImageView)
            make.leading.equalTo(lockImageView).offset(imageSize+10)
            make.trailing.equalTo(container)
            make.width.equalTo(container)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin)
        }

        showMoreLessButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(messageLabel)
        }

        infoMessagesView.snp.remakeConstraints { make in
            make.top.equalTo(showMoreLessButton.snp.bottom)
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
            make.height.equalTo(0)
        }

        upgradeButton.snp.makeConstraints { make  in
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin)
            make.top.equalTo(infoMessagesView.snp.bottom).offset(StandardVerticalMargin * 3)
            make.height.equalTo(CourseUpgradeButtonView.height)
        }
    }
    
    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "ValuePropMessageView:view"
        lockImageView.accessibilityIdentifier = "ValuePropMessageView:image-view-lock"
        titleLabel.accessibilityIdentifier = "ValuePropMessageView:label-title"
        messageLabel.accessibilityIdentifier = "ValuePropMessageView:label-message"
        showMoreLessButton.accessibilityIdentifier = "ValuePropMessageView:show-more-less-button"
        infoMessagesView.accessibilityIdentifier = "ValuePropMessageView:info-messages-view"
        upgradeButton.accessibilityIdentifier = "ValuePropMessageView:upgrade-button"
    }

    private func toggleInfoMessagesView() {
        let showingMore = self.showingMore
        let height = showingMore ? 0 : infoMessagesView.height()
        let title = showingMore ? Strings.ValueProp.showMoreText : Strings.ValueProp.showLessText
        self.showingMore = !showingMore
        trackShowMorelessAnalytics(showingMore: !showingMore)

        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let weakSelf = self else { return }

            weakSelf.showMoreLessButton.setAttributedTitle(weakSelf.showMorelessButtonStyle.attributedString(withText: title).addUnderline(), for: .normal)

            weakSelf.infoMessagesView.snp.remakeConstraints { make in
                make.top.equalTo(weakSelf.showMoreLessButton.snp.bottom).offset(StandardVerticalMargin * (showingMore ? 0 : 2))
                make.leading.equalTo(weakSelf.container)
                make.trailing.equalTo(weakSelf.container)
                make.height.equalTo(height)
            }
            
            weakSelf.layoutIfNeeded()
        })
    }

    private func upgradeCourse() {
        delegate?.didTapUpgradeCourse(upgradeView: self)
        environment.analytics.trackUpgradeNow(with: courseID, blockID: blockID, pacing: pacing)
    }

    private func trackShowMorelessAnalytics(showingMore: Bool) {
        let displayName = showingMore ? AnalyticsDisplayName.ValuePropShowMoreClicked : AnalyticsDisplayName.ValuePropShowLessClicked
        let eventName = showingMore ? AnalyticsEventName.ValuePropShowMoreClicked : AnalyticsEventName.ValuePropShowLessClicked
        environment.analytics.trackValuePropShowMoreless(with: displayName, eventName: eventName, courseID: courseID, blockID: blockID, pacing: pacing )
    }
    
    func updateUpgradeButtonVisibility(visible: Bool) {
        upgradeButton.updateVisibility(visible: visible)
    }
    
    func startAnimating() {
        upgradeButton.startAnimating()
    }
    
    func stopAnimating() {
        upgradeButton.stopAnimating()
    }
}
