//
//  CourseHTMLTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseGenericBlockTableViewCell : UITableViewCell, CourseBlockContainerCell {
    fileprivate let content = CourseOutlineItemView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        accessibilityIdentifier = "CourseGenericBlockTableViewCell:view"
        content.accessibilityIdentifier = "CourseGenericBlockTableViewCell:content-view"
    }
    
    var block : CourseBlock? = nil {
        didSet {
            if block?.isGated ?? false {
                // check env for feature flag
                let flag = true
                if flag {
                    let download = DownloadsAccessoryView()
                    download.state = .Gated
                    content.trailingView = download
                    content.setDetailText(title: Strings.ValueProp.learnHowToUnlock, blockType: block?.type, underline: true)
                } else {
                    content.setDetailText(title: Strings.courseContentGated, blockType: block?.type)
                }
                content.leadingIconColor = OEXStyles.shared().neutralBase()
            }
            content.setTitleText(title: block?.displayName)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CourseHTMLTableViewCell: CourseGenericBlockTableViewCell {
    static let identifier = "CourseHTMLTableViewCellIdentifier"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style : style, reuseIdentifier : reuseIdentifier)
        content.setContentIcon(icon: Icon.CourseHTMLContent)
        accessibilityIdentifier = "CourseHTMLTableViewCell:view"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class CourseProblemTableViewCell : CourseGenericBlockTableViewCell {
    static let identifier = "CourseProblemTableViewCellIdentifier"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style : style, reuseIdentifier : reuseIdentifier)
        content.setContentIcon(icon: Icon.CourseProblemContent)
        accessibilityIdentifier = "CourseProblemTableViewCell:view"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class CourseUnknownTableViewCell: CourseGenericBlockTableViewCell {
    
    static let identifier = "CourseUnknownTableViewCellIdentifier"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        content.leadingIconColor = OEXStyles.shared().neutralBase()
        content.setContentIcon(icon: Icon.CourseUnknownContent)
        accessibilityIdentifier = "CourseUnknownTableViewCellIdentifier:view"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class DiscussionTableViewCell: CourseGenericBlockTableViewCell {
    
    static let identifier = "DiscussionTableViewCellIdentifier"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        content.setContentIcon(icon: Icon.Discussions)
        accessibilityIdentifier = "DiscussionTableViewCell:view"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

