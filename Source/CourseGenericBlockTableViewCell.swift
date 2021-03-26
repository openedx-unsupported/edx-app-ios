//
//  CourseGenericBlockTableViewCell.swift
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
    
    var block: CourseBlock? = nil {
        didSet {
            guard let block = block else { return }

            content.setTitleText(title: block.displayName)

            if block.completion {
                if case CourseBlockDisplayType.Unknown = block.displayType  {
                    showNeutralBackground()
                } else {
                    showCompletedBackground()
                    content.setCompletionAccessibility(completion: true)
                }
            } else if block.isGated {
                showNeutralBackground()
                showValueProp(on: block)
                content.leadingIconColor = OEXStyles.shared().neutralDark()
            } else {
                showNeutralBackground()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func showNeutralBackground() {
        content.backgroundColor = OEXStyles.shared().neutralWhite()
        content.setContentIcon(icon: nil, color: .clear)
        content.setSeperatorColor(color: OEXStyles.shared().neutralXLight())
        content.setCompletionAccessibility()
    }
    
    private func showCompletedBackground() {
        content.backgroundColor = OEXStyles.shared().successXXLight()
        content.setContentIcon(icon: Icon.CheckCircle, color: OEXStyles.shared().successBase())
        content.setSeperatorColor(color: OEXStyles.shared().successXLight())
    }
    
    private func showValueProp(on block: CourseBlock) {
        if FirebaseRemoteConfiguration.shared.isValuePropEnabled {
            content.trailingView = valuePropAccessoryView
            content.setDetailText(title: Strings.ValueProp.learnHowToUnlock, blockType: block.type, underline: true)
            content.shouldShowCheckmark = false
        } else {
            content.setDetailText(title: Strings.courseContentGated, blockType: block.type)
        }
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

