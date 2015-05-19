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
    
    let headerFontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 13.0)
    let headerLabel = UILabel()
    let horizontalTopLine = UIView()
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
        addSubviews()
        setStyles()
        setConstraints()
    }

    //MARK: Helper Methods
    private func addSubviews(){
        addSubview(headerLabel)
        addSubview(horizontalTopLine)
    }
    
    private func setStyles(){
        //Using CGRectZero size because the backgroundView automatically resizes.
        backgroundView = UIView(frame: CGRectZero)
        backgroundView?.backgroundColor = OEXStyles.sharedStyles()?.standardBackgroundColor()
        
        headerFontStyle.applyToLabel(headerLabel)
        headerLabel.textColor = OEXStyles.sharedStyles()?.neutralBase()
        
        horizontalTopLine.backgroundColor = OEXStyles.sharedStyles()?.neutralBase()

    }
    
    private func setConstraints(){
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
        fatalError("init(coder:) has not been implemented")
    }
    
    
}