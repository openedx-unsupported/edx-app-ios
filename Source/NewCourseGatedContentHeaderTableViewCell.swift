//
//  NewCourseGatedContentHeaderTableViewCell.swift
//  edX
//
//  Created by MuhammadUmer on 26/04/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

class NewCourseGatedContentHeaderTableViewCell: UITableViewCell {
    static let identifier = "NewCourseGatedContentHeaderTableViewCell"
    
    private let imageSize: CGFloat = 10
    private let imageContainerSize: CGFloat = 16
    
    private lazy var titleStyle = OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralXXDark())
    private lazy var subtitleStyle = OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralXDark())
    
    private lazy var lockedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "NewCourseGatedContentHeaderTableViewCell:image-view"
        imageView.image = Icon.Closed.imageWithFontSize(size: imageSize)
        imageView.tintColor = OEXStyles.shared().neutralWhiteT()
        return imageView
    }()
    
    private lazy var imageViewContainer: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "NewCourseGatedContentHeaderTableViewCell:image-view-container"
        view.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "NewCourseGatedContentHeaderTableViewCell:title-label"
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "NewCourseGatedContentHeaderTableViewCell:subtitle-label"
        label.numberOfLines = 0
        return label
    }()
    
    private let separator = UIView()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "CourseDatesViewController:tableview-cell"
        
        addSubViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = ""
        subtitleLabel.text = ""
        contentView.backgroundColor = OEXStyles.shared().neutralWhiteT()
    }
    
    override func layoutSubviews() {
        imageViewContainer.layer.cornerRadius = imageContainerSize / 2
        imageViewContainer.clipsToBounds = true
    }
    
    private func addSubViews() {
        imageViewContainer.addSubview(lockedImageView)
        contentView.addSubview(imageViewContainer)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(separator)
        
        separator.backgroundColor = OEXStyles.shared().neutralXLight()
        
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
    
    func setup(block: CourseBlock) {
        titleLabel.attributedText = titleStyle.attributedString(withText: block.displayName)
        subtitleLabel.attributedText = subtitleStyle.attributedString(withText: "Some content in this part of the course is locked for upgraded users only.")
    }
}
