//
//  CourseSectionTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 04/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol CourseSectionTableViewCellDelegate : class {
    func sectionCellChoseDownload(cell : CourseSectionTableViewCell, block : CourseBlock)
}

class CourseSectionTableViewCell: UITableViewCell {
    
    static let identifier = "CourseSectionTableViewCellIdentifier"
    
    let content = CourseOutlineItemView(trailingImageIcon: Icon.ContentDownload)

    weak var delegate : CourseSectionTableViewCellDelegate?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }

        content.addActionForTrailingIconTap {[weak self] _ in
            if let owner = self, block = owner.block {
                owner.delegate?.sectionCellChoseDownload(owner, block: block)
            }
        }
    }
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name)
            content.isGraded = block?.graded
            
            let count = block?.blockCounts[CourseBlock.Category.Video.rawValue] ?? 0
            let visibleCount : Int? = count > 0 ? count : nil
            content.useTrailingCount(visibleCount)
            content.setTrailingIconHidden(visibleCount == nil)
            
            content.setDetailText(block?.format ?? "")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
