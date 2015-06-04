//
//  CourseSectionTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 04/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let titleLabelCenterYOffset : CGFloat = -7

class CourseSectionTableViewCell: UITableViewCell {
    
    static let identifier = "CourseSectionTableViewCellIdentifier"
    
    let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 13.0)
    let content = CourseOutlineItemView(title: "", subtitle: "", leadingImageIcon: nil, trailingImageIcon: Icon.ContentDownload)

    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name ?? "")
            content.isGraded = block?.gradedSubDAG
            //TODO: Add actual data to the subtitleLabel
            content.subtitleLabel.text = "Homework"
            //TODO: Add actual data to the downloadCountLabel
            content.downloadCountLabel.text = "3"
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
        updateCellSpecificStyles()
    }

    func updateCellSpecificStyles() {
        content.titleLabelCenterYConstraint?.updateOffset(titleLabelCenterYOffset)
        fontStyle.applyToLabel(content.titleLabel)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
