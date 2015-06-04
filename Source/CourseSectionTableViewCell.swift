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
    let content = CourseOutlineItemView(leadingImageIcon: nil, trailingImageIcon: Icon.ContentDownload)

    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name ?? "")
            content.isGraded = block?.gradedSubDAG

            let count = block?.blockCounts[CourseBlock.Category.Video.rawValue] ?? 0
            let visibleCount : Int? = count > 0 ? count : nil
            content.useTrailingCount(visibleCount)
            content.setTrailingIconHidden(visibleCount == nil)
            
            content.setDetailText(block?.format ?? "")
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
        content.useTitleStyle(fontStyle)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
