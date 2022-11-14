//
//  EnrolledCoursesFooterView.swift
//  edX
//
//  Created by Akiva Leffert on 12/23/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class EnrolledCoursesFooterView: UICollectionReusableView {
    static let identifier = "EnrolledCoursesFooterView"
    
    var findCoursesAction: (() -> Void)?
    
    private let container = UIView()
    private let bottomContainer = UIView()
    private let promptLabel = UILabel()
    
    private lazy var imageView: UIImageView = {
        guard let image = UIImage(named: "empty_state_placeholder") else { return UIImageView() }
        return UIImageView(image: image)
    }()
    
    private lazy var findCoursesButton: UIButton = {
        let button = UIButton(type: .system)
        button.oex_addAction({ [weak self] _ in
            self?.findCoursesAction?()
        }, for: .touchUpInside)
        return button
    }()
        
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
        
        addSubViews()
        setAccessibilityIdentifiers()
    }
    
    override func layoutSubviews() {
        if traitCollection.verticalSizeClass == .regular {
            addPortraitConstraints()
        } else {
            addLandscapeConstraints()
        }

        container.addShadow(offset: CGSize(width: 0, height: 2), color: OEXStyles.shared().primaryDarkColor(), radius: 2, opacity: 0.35, cornerRadius: 6)
    }
    
    private func addSubViews() {
        backgroundColor = OEXStyles.shared().neutralWhiteT()
        
        addSubview(container)

        container.addSubview(imageView)
        container.addSubview(bottomContainer)
        
        bottomContainer.addSubview(promptLabel)
        bottomContainer.addSubview(findCoursesButton)
        
        container.backgroundColor = OEXStyles.shared().neutralWhiteT()
        
        promptLabel.attributedText = findCoursesTextStyle.attributedString(withText: Strings.EnrollmentList.findCoursesPrompt)
        promptLabel.textAlignment = .center
        promptLabel.numberOfLines = 0
                
        let attributedString = NSMutableAttributedString()
        attributedString.append(attributedSearchImage)
        attributedString.append(attributedUnicodeSpace)
        attributedString.append(findCoursesButtonTextStyle.attributedString(withText: Strings.EnrollmentList.findCourses))
        findCoursesButton.setAttributedTitle(attributedString, for: UIControl.State())
        findCoursesButton.backgroundColor = OEXStyles.shared().secondaryBaseColor()
    }
    
    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "EnrolledCoursesFooterView:view"
        imageView.accessibilityIdentifier = "EnrolledCoursesFooterView:image-view"
        promptLabel.accessibilityIdentifier = "EnrolledCoursesFooterView:prompt-label"
        findCoursesButton.accessibilityIdentifier = "EnrolledCoursesFooterView:find-courses-button"
        container.accessibilityIdentifier = "EnrolledCoursesFooterView:container-view"
        bottomContainer.accessibilityIdentifier = "EnrolledCoursesFooterView:bottom-container-view"
    }
    
    private func addPortraitConstraints() {
        container.snp.remakeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin * 2)
            make.bottom.equalTo(bottomContainer.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        imageView.snp.remakeConstraints { make in
            make.top.equalTo(container)
            make.height.equalTo(StandardVerticalMargin * 33)
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
        }
        
        bottomContainer.snp.remakeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.bottom.equalTo(findCoursesButton.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
        }
        
        promptLabel.snp.remakeConstraints { make in
            make.top.equalTo(bottomContainer).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2.2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2.2)
        }
        
        findCoursesButton.snp.remakeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(StandardVerticalMargin * 3.2)
            make.bottom.equalTo(bottomContainer).inset(StandardVerticalMargin * 2)
            make.height.equalTo(StandardVerticalMargin * 5.5)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2)
        }
    }
    
    private func addLandscapeConstraints() {
        container.snp.remakeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin * 2)
            make.bottom.equalTo(self).inset(StandardVerticalMargin * 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        imageView.snp.remakeConstraints { make in
            make.top.equalTo(container)
            make.leading.equalTo(container)
            make.bottom.equalTo(container)
            make.width.equalTo(frame.size.width / 2)
        }

        bottomContainer.snp.remakeConstraints { make in
            make.top.equalTo(container).offset(-StandardVerticalMargin * 2)
            make.leading.equalTo(imageView.snp.trailing)
            make.trailing.equalTo(container)
            make.bottom.equalTo(container)
        }

        promptLabel.snp.remakeConstraints { make in
            make.top.equalTo(bottomContainer).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2)
            make.bottom.equalTo(findCoursesButton.snp.top)
        }

        findCoursesButton.snp.remakeConstraints { make in
            make.bottom.equalTo(bottomContainer).inset(StandardVerticalMargin * 4)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2)
            make.height.equalTo(StandardVerticalMargin * 5.5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
