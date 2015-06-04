//
//  CourseVideoTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 12/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


protocol CourseVideoTableViewCellDelegate : class {
    func videoCellChoseDownload(cell : CourseVideoTableViewCell, block : CourseBlock)
}

// TODO : Make a property indexPath for the table view cell and then make a delegate which takes the TouchUpInside event as "downloadButtonPressed(indexPath : NSIndexPath)" method in the delegate.
private let titleLabelCenterYOffset = -12

class CourseVideoTableViewCell: UITableViewCell {
    
    static let identifier = "CourseVideoTableViewCellIdentifier"
    weak var delegate : CourseVideoTableViewCellDelegate?
    
    let content = CourseOutlineItemView(leadingImageIcon: Icon.CourseVideoContent, trailingImageIcon: Icon.ContentDownload)
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name ?? "")
            //TODO: Set actual value of the
            content.subtitleLabel.text = "12:21"
        }
    }
        
    var state : OEXPlayedState = OEXPlayedState.Unwatched {
        didSet {
            updateIconForVideoState()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
        updateCellSpecificConstraints()
        
        content.addActionForTrailingIconTap {[weak self] _ in
            if let owner = self, block = owner.block {
                owner.delegate?.videoCellChoseDownload(owner, block : block)
            }
        }
    }
    
    func updateIconForVideoState() {
        switch state {
        case .Unwatched:
            content.leadingIconColor = OEXStyles.sharedStyles().primaryBaseColor()
            content.backgroundColor = UIColor.whiteColor()
        case .PartiallyWatched:
            content.leadingIconColor = OEXStyles.sharedStyles().primaryBaseColor()
            content.backgroundColor = OEXStyles.sharedStyles().neutralLight()
        case .Watched:
            content.leadingIconColor = OEXStyles.sharedStyles().neutralDark()
            content.backgroundColor = OEXStyles.sharedStyles().neutralLight()
        }
    }
    
    func updateCellSpecificConstraints() {
        content.titleLabelCenterYConstraint?.updateOffset(titleLabelCenterYOffset)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
