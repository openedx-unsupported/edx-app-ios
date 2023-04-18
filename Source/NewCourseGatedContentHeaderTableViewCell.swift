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
    
    private lazy var titleStyle = OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralXXDark())
    private lazy var subtitleStyle = OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralXDark())
    
    private lazy var lockedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.Closed.imageWithFontSize(size: 16)
        imageView.tintColor = OEXStyles.shared().secondaryBaseColor()
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
        
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
    
    private func addSubViews() {
        contentView.addSubview(lockedImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(lockedImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.top.equalTo(StandardVerticalMargin)
        }
        
        lockedImageView.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.height.width.equalTo(16)
        }
        
        subtitleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(lockedImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.centerY.equalTo(lockedImageView)
        }
    }
    
    func setup(block: CourseBlock) {
        titleLabel.attributedText = titleStyle.attributedString(withText: block.displayName)
        subtitleLabel.attributedText = subtitleStyle.attributedString(withText: "Some content in this part of the course is locked for upgraded users only.")
    }
}
