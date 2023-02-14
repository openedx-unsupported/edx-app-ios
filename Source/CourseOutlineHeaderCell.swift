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
            isCompleted ? showCompletedStyle() : showNeutralStyle()
        }
    }
    
    private lazy var leadingImageButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
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
        addSubviews()
        addConstraints()
        setStyles()
        setAccessibilityIdentifiers()
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "CourseOutlineHeaderCell:view"
        headerLabel.accessibilityIdentifier = "CourseOutlineHeaderCell:header-label"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Helper Methods
    private func addSubviews() {
        addSubview(leadingImageButton)
        addSubview(headerLabel)
        addSubview(button)
        addSubview(trailingImageView)
        button.superview?.bringSubviewToFront(button)
    }
    
    private func addConstraints() {
        leadingImageButton.isHidden = !isCompleted
        
        var offset: CGFloat = 2.65
        var leadingContainer: UIView = self
        
        if isCompleted {
            offset = 2.15
            leadingContainer = leadingImageButton
            
            let image = Icon.CheckCircle.imageWithFontSize(size: 17)
            leadingImageButton.setImage(image, for: .normal)
            leadingImageButton.tintColor = OEXStyles.shared().successBase()
            
            leadingImageButton.snp.remakeConstraints { make in
                make.centerY.equalTo(self)
                make.leading.equalTo(self).offset(StandardHorizontalMargin / 2)
                make.size.equalTo(iconSize)
            }
        }
        
        trailingImageView.snp.remakeConstraints { make in
            make.centerY.equalTo(self)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin / 2)
            make.size.equalTo(iconSize)
        }
        
        rotateImageView(clockWise: !isExpanded)
        
        headerLabel.snp.remakeConstraints { make in
            make.leading.equalTo(leadingContainer).offset(StandardHorizontalMargin * offset)
            make.centerY.equalTo(self)
            make.trailing.equalTo(isCompleted ? trailingImageView : self).inset(StandardHorizontalMargin * offset)
        }
        
        button.snp.remakeConstraints { make in
            make.edges.equalTo(self)
        }
        
        if OEXConfig.shared().isNewDashboardEnabled {
            leadingImageButton.isHidden = false
            trailingImageView.isHidden = false
        } else {
            leadingImageButton.isHidden = true
            trailingImageView.isHidden = true
        }
    }
    
    private func setStyles() {
        //Using CGRectZero size because the backgroundView automatically resizes.
        backgroundView = UIView(frame: .zero)        
    }
    
    func showCompletedStyle() {
        addConstraints()
        showCompletedBackground()
    }
    
    func showNeutralStyle() {
        addConstraints()
        showNeutralBackground()
    }
    
    private func showCompletedBackground() {
        updateAccessibilityLabel(completion: true)
        backgroundView?.backgroundColor = OEXStyles.shared().successXXLight()
    }
    
    private func showNeutralBackground() {
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
