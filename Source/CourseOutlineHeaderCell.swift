//
//  CourseOutlineHeaderCell.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

class CourseOutlineHeaderCell : UITableViewHeaderFooterView {
    static let identifier = "CourseOutlineHeaderCellIdentifier"
    
    var headerLabel = UILabel()
    var horizontalTopLine = UIView()
    
    var block : CourseBlock? {
        didSet {
            headerLabel.text = block?.name ?? ""
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(headerLabel)
        addSubview(horizontalTopLine)
        
        
        backgroundView = UIView(frame: CGRectMake(0, 0, 320.0, 48.0))
        backgroundView?.backgroundColor = UIColor.whiteColor()
        
        headerLabel.font = UIFont(name: "OpenSans", size: 13.0)
        headerLabel.textColor = OEXConfig.textGreyColor()
        
        horizontalTopLine.backgroundColor = OEXConfig.iconGreyColor()
        
        headerLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.snp_leading).offset(10.0)
            make.centerY.equalTo(self)
            make.trailing.equalTo(self.snp_trailing).offset(10.0)
        }
        
        horizontalTopLine.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.snp_top)
            make.leading.equalTo(self.snp_leading)
            make.trailing.equalTo(self.snp_trailing)
            make.height.equalTo(0.5)
            
        }
        
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}