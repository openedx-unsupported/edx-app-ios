//
//  CourseContentHeaderBlockPickerCell.swift
//  edX
//
//  Created by MuhammadUmer on 02/06/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

class CourseContentHeaderBlockPickerCell: UITableViewCell {
    static let identifier = "CourseContentHeaderBlockPickerCell"
    
    private let imageSize: CGFloat = 10
    private let imageContainerSize: CGFloat = 16
    private let completedImagesize: CGFloat = 16
    
    private lazy var titleStyle = OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralXXDark())
    private lazy var subtitleStyle = OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralXDark())
    
    private lazy var lockedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "CourseContentHeaderBlockPickerCell:locked-image-view"
        imageView.image = Icon.Closed.imageWithFontSize(size: imageSize)
        imageView.tintColor = OEXStyles.shared().neutralWhiteT()
        return imageView
    }()
    
    private lazy var completedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "CourseContentHeaderBlockPickerCell:completed-image-view"
        imageView.image = Icon.CheckCircle.imageWithFontSize(size: completedImagesize)
        imageView.tintColor = OEXStyles.shared().successBase()
        return imageView
    }()
    
    private lazy var imageViewContainer: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "CourseContentHeaderBlockPickerCell:image-view-container"
        view.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderBlockPickerCell:title-label"
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderBlockPickerCell:subtitle-label"
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var separator: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "CourseContentHeaderBlockPickerCell:separator-view"
        view.backgroundColor = OEXStyles.shared().neutralXLight()
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "CourseContentHeaderBlockPickerCell:tableview-cell"
        
        addSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        contentView.backgroundColor = OEXStyles.shared().neutralWhiteT()
        contentView.subviews.forEach { view in
            view.removeFromSuperview()
        }
    }
    
    override func layoutSubviews() {
        imageViewContainer.layer.cornerRadius = imageContainerSize / 2
        imageViewContainer.clipsToBounds = true
    }
    
    func setup(block: CourseBlock) {
        titleLabel.attributedText = titleStyle.attributedString(withText: block.displayName)
        subtitleLabel.text = ""
        
        if block.isGated {
            addGatedSubviews()
            completedImageView.isHidden = true
            lockedImageView.isHidden = false
            subtitleLabel.attributedText = subtitleStyle.attributedString(withText: Strings.CourseOutlineHeader.gatedContentTitle)
        } else {
            addSubviews()
            completedImageView.isHidden = !block.isCompleted
            lockedImageView.isHidden = true
        }
    }
}

extension CourseContentHeaderBlockPickerCell {
    private func addSubviews() {
        contentView.addSubview(completedImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(separator)
        
        completedImageView.snp.remakeConstraints { make in
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.height.width.equalTo(completedImagesize)
            make.centerY.equalTo(contentView)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(completedImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.centerY.equalTo(contentView)
        }
        
        separator.snp.remakeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(1)
        }
    }
}

extension CourseContentHeaderBlockPickerCell {
    private func addGatedSubviews() {
        imageViewContainer.addSubview(lockedImageView)
        contentView.addSubview(imageViewContainer)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(separator)
                
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(lockedImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.top.equalTo(contentView).offset(StandardVerticalMargin)
        }
        
        lockedImageView.snp.remakeConstraints { make in
            make.center.equalTo(imageViewContainer)
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
        }
        
        imageViewContainer.snp.remakeConstraints { make in
            make.centerY.equalTo(subtitleLabel)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.height.width.equalTo(imageContainerSize)
        }
        
        subtitleLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin * 1.25)
            make.leading.equalTo(lockedImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.centerY.equalTo(lockedImageView)
        }
        
        separator.snp.remakeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(1)
        }
    }
}
