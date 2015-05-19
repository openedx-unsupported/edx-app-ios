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

class CourseVideoTableViewCell: UITableViewCell {

    static let identifier = "CourseVideoTableViewCellIdentifier"

    let content = CourseOutlineItemView(title: "", subtitle: "", leftImageIcon: Icon.CourseVideoContent, rightImageIcon: Icon.ContentDownload)

    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name ?? "")
        }
    }
    var state : CourseVideoState {
        didSet {
            switch state{
            case .NotViewed:
                content.leadingIconColor = OEXStyles.sharedStyles()?.primaryBaseColor()
            case .PartiallyViewed:
                content.leadingIconColor = OEXStyles.sharedStyles()?.neutralBase()
            case .Completed:
                content.leadingIconColor = OEXStyles.sharedStyles()?.utilitySuccessBase()
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
            make.center.equalTo(contentView)
        }
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
