//
//  CourseVideoTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 12/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


public enum CourseVideoState : Int {
    case NotViewed = 0
    case PartiallyViewed
    case Completed
    case None
}

// TODO : Make a property indexPath for the table view cell and then make a delegate which takes the TouchUpInside event as "downloadButtonPressed(indexPath : NSIndexPath)" method in the delegate.
private let titleLabelCenterYConstraint = -12

class CourseVideoTableViewCell: UITableViewCell {
    
    static let identifier = "CourseVideoTableViewCellIdentifier"
    
    let content = CourseOutlineItemView(title: "", subtitle: "", leadingImageIcon: Icon.CourseVideoContent, trailingImageIcon: Icon.ContentDownload)
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name ?? "")
            content.subtitleLabel.text = "12:21"
        }
    }
    var state : CourseVideoState {
        didSet {
            switch state{
            case .NotViewed:
                content.leadingIconColor = OEXStyles.sharedStyles().primaryAccentColor()
            case .PartiallyViewed:
                content.leadingIconColor = OEXStyles.sharedStyles().neutralBase()
            case .Completed:
                content.leadingIconColor = OEXStyles.sharedStyles().utilitySuccessBase()
            case .None:
                content.leadingIconColor = UIColor.whiteColor()
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        state = CourseVideoState.None
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
        updateCellSpecificConstraints()
        
    }
    
    func updateCellSpecificConstraints() {
        content.titleLabelCenterYConstraint?.updateOffset(titleLabelCenterYConstraint)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}