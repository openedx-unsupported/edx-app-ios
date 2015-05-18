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

    var content = CourseContentView(title: "", subtitle: "", leftImageIcon: Icon.CourseVideoContent, rightImageIcon: Icon.ContentDownload)

    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name ?? "")
        }
    }
    var state : CourseVideoState {
        didSet {
            switch state{
            case .NotViewed:
                content.setLeftIconColor(OEXStyles.sharedStyles()?.primaryBaseColor())
            case .PartiallyViewed:
                content.setLeftIconColor(OEXStyles.sharedStyles()?.neutralBase())
            case .Completed:
                content.setLeftIconColor(OEXStyles.sharedStyles()?.utilitySuccessBase())
            case .None:
                content.setLeftIconColor(UIColor.whiteColor())
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        state = CourseVideoState.None
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.center.equalTo(self)
        }
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
