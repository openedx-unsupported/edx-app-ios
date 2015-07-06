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
    
    let headerFontStyle = OEXTextStyle(weight: .SemiBold, size: .XSmall, color : OEXStyles.sharedStyles().neutralBase())
    let headerLabel = UILabel()
    let horizontalTopLine = UIView()
    var block : CourseBlock? {
        didSet {
            headerLabel.attributedText = headerFontStyle.attributedStringWithText(block?.name)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubviews()
        setStyles()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Helper Methods
    private func addSubviews(){
        addSubview(headerLabel)
        addSubview(horizontalTopLine)
    }
    
    private func setStyles(){
        //Using CGRectZero size because the backgroundView automatically resizes.
        backgroundView = UIView(frame: CGRectZero)
        backgroundView?.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        
        horizontalTopLine.backgroundColor = OEXStyles.sharedStyles().neutralBase()

    }

    // Skip autolayout for performance reasons
    override func layoutSubviews() {
        super.layoutSubviews()
        let margin = OEXStyles.sharedStyles().standardHorizontalMargin() - 5
        self.headerLabel.frame = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(0, margin, 0, margin))
        horizontalTopLine.frame = CGRectMake(0, 0, self.bounds.size.width, OEXStyles.dividerSize())
    }
}