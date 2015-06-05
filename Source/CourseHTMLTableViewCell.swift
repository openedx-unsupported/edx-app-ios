//
//  CourseHTMLTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseHTMLTableViewCell: UITableViewCell {
    
    enum Kind {
        case HTML
        case Problem
    }
    
    static let identifier = "CourseHTMLTableViewCellIdentifier"
    
    private let content = CourseOutlineItemView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        content.isGraded = false
        content.setDetailText("")
        content.setContentIcon(nil)
    }
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name ?? "")
        }
    }
    
    class func kindForBlockType(blockType : CourseBlockType) -> Kind? {
        switch blockType {
        case .HTML:
            return .HTML
        case .Problem:
            return .Problem
        default:
            return nil
        }
    }
    
    var kind : Kind? {
        didSet {
            if let kind = kind {
                switch kind {
                case .HTML: content.setContentIcon(Icon.CourseHTMLContent)
                case .Problem: content.setContentIcon(Icon.CourseProblemContent)
                }
            }
            else {
                content.setContentIcon(nil)
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}