//
//  NewCourseContentHeaderTableViewCell.swift
//  edX
//
//  Created by MuhammadUmer on 26/04/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

class NewCourseContentHeaderTableViewCell: UITableViewCell {
    static let identifier = "NewCourseContentHeaderTableViewCell"
    
    private lazy var titleStyle = OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralXXDark())
    private lazy var completedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.CheckCircle.imageWithFontSize(size: 16)
        imageView.tintColor = OEXStyles.shared().successBase()
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
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
        completedImageView.isHidden = true
        contentView.backgroundColor = OEXStyles.shared().neutralWhiteT()
    }
    
    private func addSubViews() {
        contentView.addSubview(completedImageView)
        contentView.addSubview(titleLabel)
        
        completedImageView.snp.remakeConstraints { make in
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.height.width.equalTo(13)
            make.centerY.equalTo(contentView)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(completedImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.centerY.equalTo(contentView)
        }
    }
    
    func setup(block: CourseBlock) {
        titleLabel.attributedText = titleStyle.attributedString(withText: block.displayName)
        completedImageView.isHidden = !block.isCompleted
    }
}
