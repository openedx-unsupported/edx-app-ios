//
//  CourseOutlineTableViewCell.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseOutlineTableViewCell : UITableViewCell {
    
    static let identifier = "CourseOutlineTableViewCellIdentifier"
    
    var block : CourseBlock? = nil {
        didSet {
            textLabel?.text = block?.name ?? ""
        }
    }
}