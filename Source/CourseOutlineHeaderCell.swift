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
    func toggleSection(section: Int)
}

class CourseOutlineHeaderCell: UITableViewHeaderFooterView {
    
    static let identifier = "CourseOutlineHeaderCellIdentifier"
    
    weak var delegate: CourseOutlineHeaderCellDelegate?
    
    var section = 0
    
    private var isExpanded = false
    private var isCompleted = false
    
    private let horizontalTopLine = UIView()
    private let containerView = UIView()
    private let iconSize = CGSize(width: 25, height: 25)
    private let headerLabel = UILabel()
    
    private lazy var headerFontStyle: OEXTextStyle = {
        if OEXConfig.shared().isNewDashboardEnabled {
            return OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralBlackT())
        }
        return OEXTextStyle(weight: .semiBold, size: .xSmall, color: OEXStyles.shared().neutralXDark())
    }()
    
    private lazy var leadingImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.accessibilityIdentifier = "CourseOutlineHeaderCell:trailing-button-view"
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
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "CourseOutlineHeaderCell:button-view"
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
    
    func setupViewsNewDesign(isExpanded: Bool, isCompleted: Bool) {
        self.isExpanded = isExpanded
        self.isCompleted = isCompleted
        
        addSubviewsForNewDesign()
        setConstraintsForNewDesign()
        setAccessibilityIdentifiers()
        backgroundView = UIView(frame: .zero)
        containerView.applyBorderStyle(style: BorderStyle(cornerRadius: .Size(0), width: .Size(1), color: OEXStyles.shared().neutralDark()))
    }
    
    func setupViewsForOldDesign() {
        addSubviewsForOldDesign()
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "CourseOutlineHeaderCell:view"
        headerLabel.accessibilityIdentifier = "CourseOutlineHeaderCell:header-label"
        horizontalTopLine.accessibilityIdentifier = "CourseOutlineHeaderCell:horizontal-top-line"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviewsForNewDesign() {
        addSubview(containerView)
        containerView.addSubview(leadingImageButton)
        containerView.addSubview(headerLabel)
        containerView.addSubview(button)
        containerView.addSubview(trailingImageView)
        button.superview?.bringSubviewToFront(button)
    }
    
    func setConstraintsForNewDesign() {
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
        
        headerLabel.snp.remakeConstraints { make in
            make.leading.equalTo(leadingImageButton).offset(StandardHorizontalMargin * 2.15)
            make.centerY.equalTo(containerView)
            make.trailing.equalTo(trailingImageView.snp.leading).offset(-StandardHorizontalMargin * 2.15)
        }
        
        button.snp.remakeConstraints { make in
            make.edges.equalTo(containerView)
        }
        
        rotateImageView(clockWise: isExpanded)
    }
    
    private func addSubviewsForOldDesign() {
        addSubview(horizontalTopLine)
        addSubview(headerLabel)
        backgroundView = UIView(frame: .zero)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if subviews.contains(headerLabel) && subviews.contains(horizontalTopLine) {
            let margin = StandardHorizontalMargin - 5
            headerLabel.frame = bounds.inset(by: UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin))
            horizontalTopLine.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: OEXStyles.dividerSize())
        }
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
        delegate?.toggleSection(section: section)
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
