//
//  CourseHTMLTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseGenericBlockTableViewCell : UITableViewCell {
    private let content = CourseOutlineItemView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
    }
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CourseHTMLTableViewCell: CourseGenericBlockTableViewCell {
    static let identifier = "CourseHTMLTableViewCellIdentifier"
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style : style, reuseIdentifier : reuseIdentifier)
        content.setContentIcon(Icon.CourseHTMLContent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class CourseProblemTableViewCell : CourseGenericBlockTableViewCell {
    static let identifier = "CourseProblemTableViewCellIdentifier"
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style : style, reuseIdentifier : reuseIdentifier)
        content.setContentIcon(Icon.CourseProblemContent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class CourseUnknownTableViewCell: CourseGenericBlockTableViewCell {
    
    static let identifier = "CourseUnknownTableViewCellIdentifier"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        content.leadingIconColor = OEXStyles.sharedStyles().neutralBase()
        content.setContentIcon(Icon.CourseUnknownContent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

