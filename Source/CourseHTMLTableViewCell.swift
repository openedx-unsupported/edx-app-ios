//
//  CourseHTMLTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseHTMLTableViewCell: UITableViewCell {

    static let identifier = "CourseHTMLTableViewCellIdentifier"
    
    var content = CourseContentView(title: "", subtitle: "", leftImageIcon: Icon.CourseHTMLContent, rightImageIcon: nil)
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name ?? "")
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
