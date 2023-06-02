//
//  CourseContentHeaderTableViewCell.swift
//  edX
//
//  Created by MuhammadUmer on 02/06/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

class CourseContentHeaderTableViewCell: UITableViewCell {
    static let identifier = "CourseContentHeaderTableViewCell"
    
    private let imageSize: CGFloat = 10
    private let imageContainerSize: CGFloat = 16
    
    private lazy var titleStyle = OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralXXDark())
    private lazy var subtitleStyle = OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralXDark())
    
    private lazy var lockedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "CourseContentHeaderTableViewCell:locked-image-view"
        imageView.image = Icon.Closed.imageWithFontSize(size: imageSize)
        imageView.tintColor = OEXStyles.shared().neutralWhiteT()
        return imageView
    }()
    
    private lazy var completedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "CourseContentHeaderTableViewCell:completed-image-view"
        imageView.image = Icon.CheckCircle.imageWithFontSize(size: 16)
        imageView.tintColor = OEXStyles.shared().successBase()
        return imageView
    }()
    
    private lazy var imageViewContainer: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "CourseContentHeaderTableViewCell:image-view-container"
        view.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderTableViewCell:title-label"
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderTableViewCell:subtitle-label"
        label.numberOfLines = 0
        return label
    }()
    
    private let separator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "CourseContentHeaderTableViewCell:tableview-cell"
        
        addSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = ""
        subtitleLabel.text = ""
        lockedImageView.isHidden = true
        completedImageView.isHidden = true
        contentView.backgroundColor = OEXStyles.shared().neutralWhiteT()
    }
    
    override func layoutSubviews() {
        imageViewContainer.layer.cornerRadius = imageContainerSize / 2
        imageViewContainer.clipsToBounds = true
    }
    
    private func addSubviews() {
        imageViewContainer.addSubview(lockedImageView)
        contentView.addSubview(completedImageView)
        contentView.addSubview(imageViewContainer)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(separator)
        
        separator.backgroundColor = OEXStyles.shared().neutralXLight()
        
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(imageViewContainer.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.top.equalTo(contentView).offset(StandardVerticalMargin)
        }
        
        lockedImageView.snp.remakeConstraints { make in
            make.center.equalTo(imageViewContainer)
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
        }
        
        completedImageView.snp.remakeConstraints { make in
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.centerY.equalTo(titleLabel)
            make.height.width.equalTo(16)
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

    func setup(block: CourseBlock) {
        titleLabel.attributedText = titleStyle.attributedString(withText: block.displayName)
        
        if block.isGated {
            subtitleLabel.attributedText = subtitleStyle.attributedString(withText: Strings.CourseOutlineHeader.gatedContentTitle)
            imageViewContainer.isHidden = false
            lockedImageView.isHidden = false
            completedImageView.isHidden = true
        } else {
            imageViewContainer.isHidden = true
            subtitleLabel.attributedText = nil
            lockedImageView.isHidden = true
            completedImageView.isHidden = !block.isCompleted
            
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(imageViewContainer.snp.trailing).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.centerY.equalTo(contentView)
            }
        }
    }
}
