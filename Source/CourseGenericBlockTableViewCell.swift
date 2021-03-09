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
    
    private lazy var valuePropAccessoryView: DownloadsAccessoryView = {
        let view = DownloadsAccessoryView()
        view.state = .Gated
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        accessibilityIdentifier = "CourseGenericBlockTableViewCell:view"
        content.accessibilityIdentifier = "CourseGenericBlockTableViewCell:content-view"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var block: CourseBlock? {
        didSet {
            setupCell()
        }
    }
    
    private func setupCell() {
        guard let block = block else { return }
        
        if block.completion {
            content.backgroundColor = OEXStyles.shared().successXXLight()
            content.setContentIcon(icon: Icon.CheckCircle, color: OEXStyles.shared().successBase())
        } else {
            content.backgroundColor = OEXStyles.shared().neutralWhite()
            content.setContentIcon(icon: nil, color: .clear)
        }
                
        if block.isGated {
            content.leadingIconColor = OEXStyles.shared().neutralXLight()
            
            if FirebaseRemoteConfiguration.shared.isValuePropEnabled {
                content.trailingView = valuePropAccessoryView
                content.setDetailText(title: Strings.ValueProp.learnHowToUnlock, blockType: block.type, underline: true)
            } else {
                content.setDetailText(title: Strings.courseContentGated, blockType: block.type)
            }
        } else {
            content.leadingIconColor = OEXStyles.shared().neutralXXDark()
        }
        
        content.setTitleText(title: block.displayName)
    }
}

class CourseHTMLTableViewCell: CourseGenericBlockTableViewCell {
    static let identifier = "CourseHTMLTableViewCellIdentifier"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style : style, reuseIdentifier : reuseIdentifier)
        content.setTitleTrailingIcon(icon: Icon.CourseHTMLContent)
        accessibilityIdentifier = "CourseHTMLTableViewCell:view"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CourseOpenAssesmentTableViewCell: CourseGenericBlockTableViewCell {
    static let identifier = "CourseOpenAssesmentTableViewCelldentifier"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style : style, reuseIdentifier : reuseIdentifier)
        content.setTitleTrailingIcon(icon: Icon.CourseOpenAssesmentContent)
        accessibilityIdentifier = "CourseOpenAssesmentTableViewCell:view"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CourseProblemTableViewCell : CourseGenericBlockTableViewCell {
    static let identifier = "CourseProblemTableViewCellIdentifier"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style : style, reuseIdentifier : reuseIdentifier)
        content.setTitleTrailingIcon(icon: Icon.CourseProblemContent)
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
        content.leadingIconColor = OEXStyles.shared().neutralXLight()
        content.setTitleTrailingIcon(icon: Icon.CourseUnknownContent)
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
        content.setTitleTrailingIcon(icon: Icon.Discussions)
        accessibilityIdentifier = "DiscussionTableViewCell:view"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

