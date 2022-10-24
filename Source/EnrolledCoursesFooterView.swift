//
//  EnrolledCoursesFooterView.swift
//  edX
//
//  Created by Akiva Leffert on 12/23/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class EnrolledCoursesEmptyState: UIView {
    private lazy var imageView: UIImageView = {
        guard let image = UIImage(named: "empty_state_placeholder") else { return UIImageView() }
        return UIImageView(image: image)
    }()
    
    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        
        return label
    }()
    
    private let findCoursesButton = UIButton(type: .system)
    private let container = UIView()
    
    var findCoursesAction : (() -> Void)?
    
    private var findCoursesTextStyle: OEXTextStyle {
        return OEXTextStyle(weight: .bold, size: .xxLarge, color: OEXStyles.shared().neutralBlackT())
    }
    
    private var findCoursesButtonTextStyle: OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().neutralWhite())
    }
    
    private let attributedUnicodeSpace = NSAttributedString(string: "\u{3000}")
    
    private var attributedSearchImage: NSAttributedString {
        let lockImage = Icon.Search.imageWithFontSize(size: 22).image(with: OEXStyles.shared().neutralWhite())
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = lockImage
        
        let imageOffsetY: CGFloat = -4.0
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: image.size.width, height: image.size.height)
        }
        
        return NSAttributedString(attachment: imageAttachment)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        addSubview(container)
        container.addSubview(promptLabel)
        container.addSubview(findCoursesButton)
        
        promptLabel.attributedText = findCoursesTextStyle.attributedString(withText: Strings.EnrollmentList.findCoursesPrompt)
        promptLabel.textAlignment = .center
        
        findCoursesButton.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        
        let attributedString = NSMutableAttributedString()
        attributedString.append(attributedSearchImage)
        attributedString.append(attributedUnicodeSpace)
        attributedString.append(findCoursesButtonTextStyle.attributedString(withText: Strings.EnrollmentList.findCourses))
        
        findCoursesButton.setAttributedTitle(attributedString, for: UIControl.State())
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.height.equalTo(StandardVerticalMargin * 33)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        container.backgroundColor = .white
        container.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.bottom.equalTo(findCoursesButton.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        promptLabel.snp.makeConstraints { make in
            make.top.equalTo(container).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin)
        }
        
        findCoursesButton.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.bottom.equalTo(container).inset(StandardVerticalMargin * 2)
            make.height.equalTo(StandardVerticalMargin * 5.5)
            make.leading.equalTo(promptLabel)
            make.trailing.equalTo(promptLabel)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let EnrolledCoursesFooterViewHeight: CGFloat = 100

class EnrolledCoursesFooterView : UICollectionReusableView {
    static let identifier = "EnrolledCoursesFooterView"
    
    private let promptLabel = UILabel()
    private let findCoursesButton = UIButton(type:.system)
    
    private let container = UIView()
    
    var findCoursesAction : (() -> Void)?
    
    private var findCoursesTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXDark())
    }
    
    override init(frame: CGRect) {    
        super.init(frame: CGRect.zero)
        
        addSubview(container)
        container.addSubview(promptLabel)
        container.addSubview(findCoursesButton)
        
        self.promptLabel.attributedText = findCoursesTextStyle.attributedString(withText: Strings.EnrollmentList.findCoursesPrompt)
        self.promptLabel.textAlignment = .center
        
        self.findCoursesButton.applyButtonStyle(style: OEXStyles.shared().filledPrimaryButtonStyle, withTitle: Strings.EnrollmentList.findCourses.oex_uppercaseStringInCurrentLocale())
        
        container.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        container.applyBorderStyle(style: BorderStyle())
        
        container.snp.makeConstraints { make in
            make.top.equalTo(self).offset(CourseCardCell.margin)
            make.bottom.equalTo(self)
            make.leading.equalTo(self).offset(CourseCardCell.margin)
            make.trailing.equalTo(self).offset(-CourseCardCell.margin)
        }
        
        self.promptLabel.snp.makeConstraints { make in
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).offset(-StandardHorizontalMargin)
            make.top.equalTo(container).offset(StandardVerticalMargin)
        }
        
        self.findCoursesButton.snp.makeConstraints { make in
            make.leading.equalTo(promptLabel)
            make.trailing.equalTo(promptLabel)
            make.top.equalTo(promptLabel.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(container).offset(-StandardVerticalMargin)
        }
        
        findCoursesButton.oex_addAction({[weak self] _ in
            self?.findCoursesAction?()
            }, for: .touchUpInside)

        setAccessibilityIdentifiers()
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "EnrolledCoursesFooterView:view"
        promptLabel.accessibilityIdentifier = "EnrolledCoursesFooterView:prompt-label"
        findCoursesButton.accessibilityIdentifier = "EnrolledCoursesFooterView:find-courses-button"
        container.accessibilityIdentifier = "EnrolledCoursesFooterView:container-view"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
