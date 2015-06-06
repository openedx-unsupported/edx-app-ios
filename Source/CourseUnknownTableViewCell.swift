//
//  CourseUnknownTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownTableViewCell: UITableViewCell {
    
    static let identifier = "CourseUnknownTableViewCellIdentifier"
    
    let content = CourseOutlineItemView(leadingImageIcon: Icon.CourseUnknownContent)
    //TODO : Update the subtitle text when incorporating the model
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name ?? "")
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        content.leadingIconColor = OEXStyles.sharedStyles().neutralBase()
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}