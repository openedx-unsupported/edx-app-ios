//
//  UpgradeCourseValuePropViewController.swift
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

class UpgradeCourseValuePropViewController: UIViewController {

    private let titleLabel = UILabel()
    private let messageTitleLabel = UILabel()
    private let pointOneLabel = UILabel()
    private let pointTwoLabel = UILabel()
    private let pointThreeLabel = UILabel()
    private let pointFourLabel = UILabel()
    private let pointOneBulletImageView = UIImageView()
    private let pointTwoBulletImageView = UIImageView()
    private let pointThreeBulletImageView = UIImageView()
    private let pointFourBulletImageView = UIImageView()
    private let certificateImageView = UIImageView()
    private let messageContainer = UIView()
    private let pointOneMessageContainer = UIView()
    private let pointTwoMessageContainer = UIView()
    private let pointThreeMessageContainer = UIView()
    private let pointFourMessageContainer = UIView()
    private let contentView = UIView()
    private let scrollView = UIScrollView()
    private let titleLabelFontstyle = OEXMutableTextStyle(weight: .normal, size: .xxxLarge, color: OEXStyles.shared().primaryDarkColor())
    private var type: ValuePropModalType
    private var course: OEXCourse
    
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
        setTitle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setTitle() {
        titleLabel.numberOfLines = 2
        titleLabelFontstyle.alignment = .center
        let titleString = type == .courseEnrollment ? Strings.UpgradeCourseValueProp.detailViewTitle : ""
        titleLabel.attributedText = titleLabelFontstyle.attributedString(withText: titleString)
    }
    
    private func screenAnalytics() {
        let screenName = (type == .courseEnrollment) ? AnalyticsScreenName.ValuePropModalForCourseEnrollment : AnalyticsScreenName.ValuePropModalForCourseUnit
        OEXAnalytics.shared().trackValueProModal(withName: screenName, courseId: course.course_id ?? "", userID: OEXSession.shared()?.currentUser?.userId?.intValue ?? 0)
    }
    
    private func configureView() {
        scrollView.contentSize = contentView.frame.size
        messageTitleLabel.attributedText = titleLabelFontstyle.attributedString(withText: Strings.UpgradeCourseValueProp.detailViewMessageHeading)
        pointOneBulletImageView.image = Icon.CheckCircleO.imageWithFontSize(size: 28)
        pointTwoBulletImageView.image = Icon.CheckCircleO.imageWithFontSize(size: 28)
        pointThreeBulletImageView.image = Icon.CheckCircleO.imageWithFontSize(size: 28)
        pointFourBulletImageView.image = Icon.CheckCircleO.imageWithFontSize(size: 28)
        
        let pointLabelFontstyle = OEXMutableTextStyle(weight: .light, size: .large, color: OEXStyles.shared().primaryDarkColor())
        
        pointOneLabel.numberOfLines = 3
        pointTwoLabel.numberOfLines = 3
        pointThreeLabel.numberOfLines = 3
        pointFourLabel.numberOfLines = 3
        
        pointOneLabel.attributedText = pointLabelFontstyle.attributedString(withText: Strings.UpgradeCourseValueProp.detailViewMessagePointOne)
        pointTwoLabel.attributedText = pointLabelFontstyle.attributedString(withText: Strings.UpgradeCourseValueProp.detailViewMessagePointTwo)
        pointThreeLabel.attributedText = pointLabelFontstyle.attributedString(withText: Strings.UpgradeCourseValueProp.detailViewMessagePointThree)
        pointFourLabel.attributedText = pointLabelFontstyle.attributedString(withText: Strings.UpgradeCourseValueProp.detailViewMessagePointFour)
        
        certificateImageView.image = UIImage(named: "courseCertificate.png")
        
        addViews()
        setUpConstraint()
    }
    
    private func addViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(certificateImageView)
        contentView.addSubview(messageContainer)
        messageContainer.addSubview(pointOneMessageContainer)
        messageContainer.addSubview(pointTwoMessageContainer)
        messageContainer.addSubview(pointThreeMessageContainer)
        messageContainer.addSubview(pointFourMessageContainer)
        messageContainer.addSubview(messageTitleLabel)
        pointOneMessageContainer.addSubview(pointOneBulletImageView)
        pointOneMessageContainer.addSubview(pointOneLabel)
        pointTwoMessageContainer.addSubview(pointTwoBulletImageView)
        pointTwoMessageContainer.addSubview(pointTwoLabel)
        pointThreeMessageContainer.addSubview(pointThreeBulletImageView)
        pointThreeMessageContainer.addSubview(pointThreeLabel)
        pointFourMessageContainer.addSubview(pointFourBulletImageView)
        pointFourMessageContainer.addSubview(pointFourLabel)
        addCloseButton()
    }
    
    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: 30), style: .plain, target: nil, action: nil)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "UpgradeCourseValuePropView:close-button"
        navigationItem.rightBarButtonItem = closeButton
        
        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func setUpConstraint() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        
        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.bottom.equalTo(scrollView)
            make.height.equalTo(scrollView).priority(.low)
            make.width.equalTo(scrollView)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).offset(StandardHorizontalMargin*2)
            make.centerX.equalTo(contentView)
            make.width.equalTo(300)
        }
        
        certificateImageView.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardHorizontalMargin*2)
            make.centerX.equalTo(contentView)
        }
        
        messageContainer.snp.makeConstraints { (make) in
            make.top.equalTo(certificateImageView.snp.bottom).offset(StandardHorizontalMargin*2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(contentView)
        }
        
        messageTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(messageContainer)
            make.leading.equalTo(messageContainer).offset(StandardVerticalMargin)
        }
        
        pointOneMessageContainer.snp.makeConstraints { (make) in
            make.top.equalTo(messageTitleLabel.snp.bottom).offset(StandardHorizontalMargin*2)
            make.leading.equalTo(messageContainer)
            make.trailing.equalTo(messageContainer)
            make.height.equalTo(60)
        }
        
        pointTwoMessageContainer.snp.makeConstraints { (make) in
            make.top.equalTo(pointOneMessageContainer.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(messageContainer)
            make.trailing.equalTo(messageContainer)
            make.height.equalTo(60)
        }
        
        pointThreeMessageContainer.snp.makeConstraints { (make) in
            make.top.equalTo(pointTwoMessageContainer.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(messageContainer)
            make.trailing.equalTo(messageContainer)
            make.height.equalTo(60)
        }
        
        pointFourMessageContainer.snp.makeConstraints { (make) in
            make.top.equalTo(pointThreeMessageContainer.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(messageContainer)
            make.trailing.equalTo(messageContainer)
            make.bottom.equalTo(messageContainer)
            make.height.equalTo(60)
        }
        
        pointOneBulletImageView.snp.makeConstraints { (make) in
            make.top.equalTo(pointOneMessageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(pointOneMessageContainer).offset(StandardVerticalMargin)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        
        pointOneLabel.snp.makeConstraints { (make) in
            make.top.equalTo(pointOneMessageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(pointOneBulletImageView.snp.trailing).offset(StandardVerticalMargin)
            make.trailing.equalTo(pointOneMessageContainer)
        }
    
        pointTwoBulletImageView.snp.makeConstraints { (make) in
            make.top.equalTo(pointTwoMessageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(pointTwoMessageContainer).offset(StandardVerticalMargin)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        
        pointTwoLabel.snp.makeConstraints { (make) in
            make.top.equalTo(pointTwoMessageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(pointTwoBulletImageView.snp.trailing).offset(StandardVerticalMargin)
            make.trailing.equalTo(pointTwoMessageContainer)
        }
        
        pointThreeBulletImageView.snp.makeConstraints { (make) in
            make.top.equalTo(pointThreeMessageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(pointThreeMessageContainer).offset(StandardVerticalMargin)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        
        pointThreeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(pointThreeMessageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(pointThreeBulletImageView.snp.trailing).offset(StandardVerticalMargin)
            make.trailing.equalTo(pointThreeMessageContainer)
        }
        
        pointFourBulletImageView.snp.makeConstraints { (make) in
            make.top.equalTo(pointFourMessageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(pointFourMessageContainer).offset(StandardVerticalMargin)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        
        pointFourLabel.snp.makeConstraints { (make) in
            make.top.equalTo(pointFourMessageContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(pointFourBulletImageView.snp.trailing).offset(StandardVerticalMargin)
            make.trailing.equalTo(pointFourMessageContainer)
        }
    }
}
