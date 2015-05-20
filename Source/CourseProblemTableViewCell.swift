//
//  CourseProblemTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseProblemTableViewCell: UITableViewCell {

    static let identifier = "CourseProblemTableViewCellIdentifier"

    let content = CourseOutlineItemView(title: "", subtitle: "", leadingImageIcon: Icon.CourseProblemContent, trailingImageIcon: nil)

    var block : CourseBlock? = nil {
        didSet {
           content.setTitleText(block?.name ?? "")
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
      
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
