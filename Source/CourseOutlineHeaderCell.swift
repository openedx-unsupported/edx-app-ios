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
    
    let headerFontStyle = OEXTextStyle(weight: .semiBold, size: .xSmall, color: OEXStyles.shared().neutralXDark())
    let headerLabel = UILabel()
    let horizontalTopLine = UIView()
    
    var block: CourseBlock? {
        didSet {
            headerLabel.attributedText = headerFontStyle.attributedString(withText: block?.displayName)
            setStyles()
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubviews()
        setStyles()
        setAccessibilityIdentifiers()
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "CourseOutlineHeaderCell:view"
        headerLabel.accessibilityIdentifier = "CourseOutlineHeaderCell:header-label"
        horizontalTopLine.accessibilityIdentifier = "CourseOutlineHeaderCell:horizontal-top-line"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Helper Methods
    private func addSubviews() {
        addSubview(headerLabel)
        addSubview(horizontalTopLine)
    }
    
    private func setStyles() {
        //Using CGRectZero size because the backgroundView automatically resizes.
        backgroundView = UIView(frame: .zero)
        
        if let block = block {
            block.completion ? showGreenBackground() : showNeutralBackground()
        } else {
            backgroundView?.backgroundColor = OEXStyles.shared().neutralWhite()
        }
        
        horizontalTopLine.backgroundColor = OEXStyles.shared().neutralBase()
    }
    
    func showGreenBackground() {
        backgroundView?.backgroundColor = OEXStyles.shared().successXXLight()
    }
    
    func showNeutralBackground() {
        backgroundView?.backgroundColor = OEXStyles.shared().neutralWhite()
    }

    // Skip autolayout for performance reasons
    override func layoutSubviews() {
        super.layoutSubviews()
        let margin = StandardHorizontalMargin - 5
        headerLabel.frame = bounds.inset(by: UIEdgeInsets.init(top: 0, left: margin, bottom: 0, right: margin))
        horizontalTopLine.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: OEXStyles.dividerSize())
    }
}
