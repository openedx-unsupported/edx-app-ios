//
//  CourseOutlineHeaderCell.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

protocol CourseOutlineHeaderCellDelegate: AnyObject {
    func toggleSection(header: CourseOutlineHeaderCell, section: Int)
}

class CourseOutlineHeaderCell: UITableViewHeaderFooterView {
    
    weak var delegate: CourseOutlineHeaderCellDelegate?
    var section = 0
    
    static let identifier = "CourseOutlineHeaderCellIdentifier"
    
    var isTapActionEnabled = false
    var isExpanded = false
    var isCompleted = false {
        didSet {
            if isCompleted {
                showCompletedBackground()
            } else {
                showNeutralBackground()
            }
            addConstraints()
        }
    }
    
    private let horizontalTopLine = UIView()
    private let containerView = UIView()
    
    private lazy var leadingImageButton: UIButton = {
        let button = UIButton(type: .system)
        let image = Icon.CheckCircle.imageWithFontSize(size: 17)
        button.setImage(image, for: .normal)
        button.tintColor = OEXStyles.shared().successBase()
        button.isHidden = true
        return button
    }()
    
    private lazy var trailingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "CourseOutlineHeaderCell:trailing-image-view"
        imageView.image = Icon.ExpandMore.imageWithFontSize(size: 24)
        imageView.tintColor = OEXStyles.shared().neutralDark()
        return imageView
    }()
    
    private let iconSize = CGSize(width: 25, height: 25)
    
    private let headerFontStyle = OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralBlackT())
    private let headerLabel = UILabel()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.oex_addAction({ [weak self] _ in
            self?.handleTap()
        }, for: .touchUpInside)
        return button
    }()
    
    var block: CourseBlock? {
        didSet {
            headerLabel.attributedText = headerFontStyle.attributedString(withText: block?.displayName)
            headerLabel.accessibilityLabel = block?.displayName
            setStyles()
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    func setup() {
        addSubviews()
        addConstraints()
        setAccessibilityIdentifiers()
        backgroundView = UIView(frame: .zero)
        containerView.applyBorderStyle(style: BorderStyle(cornerRadius: .Size(0), width: .Size(1), color: OEXStyles.shared().neutralDark()))
    }
    
    func setupOld() {
        addSubviewsOld()
        
        let margin = StandardHorizontalMargin - 5
        
        headerLabel.snp.remakeConstraints { make in
            make.leading.equalTo(self).offset(margin)
            make.trailing.equalTo(self).offset(margin)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
        
        horizontalTopLine.snp.remakeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(OEXStyles.dividerSize())
        }
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "CourseOutlineHeaderCell:view"
        headerLabel.accessibilityIdentifier = "CourseOutlineHeaderCell:header-label"
        horizontalTopLine.accessibilityIdentifier = "CourseOutlineHeaderCell:horizontal-top-line"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        addSubview(containerView)
        containerView.addSubview(leadingImageButton)
        containerView.addSubview(headerLabel)
        containerView.addSubview(button)
        containerView.addSubview(trailingImageView)
        button.superview?.bringSubviewToFront(button)
    }
    
    func addConstraints() {
        leadingImageButton.isHidden = !isCompleted
        
        containerView.snp.remakeConstraints { make in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        leadingImageButton.snp.remakeConstraints { make in
            make.centerY.equalTo(containerView)
            make.leading.equalTo(containerView).offset(StandardHorizontalMargin / 2)
            make.size.equalTo(iconSize)
        }
        
        trailingImageView.snp.remakeConstraints { make in
            make.centerY.equalTo(containerView)
            make.trailing.equalTo(containerView).inset(StandardHorizontalMargin / 2)
            make.size.equalTo(iconSize)
        }
        
        rotateImageView(clockWise: !isExpanded)
        
        headerLabel.snp.remakeConstraints { make in
            make.leading.equalTo(leadingImageButton).offset(StandardHorizontalMargin * 2.15)
            make.centerY.equalTo(containerView)
            make.trailing.equalTo(trailingImageView.snp.leading).offset(-StandardHorizontalMargin * 2.15)
        }
        
        button.snp.remakeConstraints { make in
            make.edges.equalTo(containerView)
        }
    }
    
    private func addSubviewsOld() {
        addSubview(horizontalTopLine)
        addSubview(headerLabel)
        backgroundView = UIView(frame: .zero)
    }
    
    private func setStyles() {
        backgroundView = UIView(frame: .zero)
        horizontalTopLine.backgroundColor = OEXStyles.shared().neutralBase()
    }
    
    func showCompletedBackground() {
        updateAccessibilityLabel(completion: true)
        backgroundView?.backgroundColor = OEXStyles.shared().successXXLight()
    }
    
    func showNeutralBackground() {
        updateAccessibilityLabel(completion: false)
        backgroundView?.backgroundColor = OEXStyles.shared().neutralWhite()
    }

    private func updateAccessibilityLabel(completion: Bool) {
        headerLabel.accessibilityHint = completion ? Strings.Accessibility.completed : nil
    }
    
    private func handleTap() {
        guard OEXConfig.shared().isNewDashboardEnabled else { return }
        
        if isExpanded {
            rotateImageView(clockWise: true)
        } else {
            rotateImageView(clockWise: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.delegate?.toggleSection(header: self, section: self.section)
        }
    }
    
    private func rotateImageView(clockWise: Bool) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let weakSelf = self else { return }
            if clockWise {
                weakSelf.trailingImageView.transform = weakSelf.trailingImageView.transform.rotated(by: -(.pi * 0.999))
            } else {
                weakSelf.trailingImageView.transform = .identity
            }
        }
    }
}
