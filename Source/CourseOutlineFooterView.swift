//
//  CourseOutlineFooterView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseOutlineFooterView: UITableViewHeaderFooterView {

    static let identifier = "CourseOutlineFooterViewIdentifier"
    
    let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0)
    let smallFontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 13.0)
    
    var nextSubSectionView = UIView()
    var nextSubSectionLabel = UILabel()
    var subSectionTitleLabel = UILabel()
    var bottomBar = UIView()
    var nextButton = UIButton()
    var previousButton = UIButton()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubviews()
        setStyles()
        setConstraints()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Helper Methods
    private func setStyles()
    {
        nextSubSectionView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        fontStyle.applyToLabel(nextSubSectionLabel)
        nextSubSectionLabel.textColor = OEXStyles.sharedStyles().neutralXDark()
        
        smallFontStyle.applyToLabel(subSectionTitleLabel)
        
        nextButton.setTitle("NEXT", forState: .Normal)
        nextButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        nextButton.titleLabel?.font = UIFont(name: "OpenSans-Semibold", size: 13.0)
        
        previousButton.setTitle("PREVIOUS", forState: .Normal)
        previousButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        previousButton.titleLabel?.font = UIFont(name: "OpenSans-Semibold", size: 13.0)
        
        nextSubSectionLabel.text = "Next Subsection"
        subSectionTitleLabel.text = "Homework 1: Your First Grade"
    }
    
    private func addSubviews()
    {
        backgroundView = UIView(frame: CGRectMake(0, 0, self.frame.width, 100.0))
        backgroundView?.backgroundColor = UIColor.whiteColor()
        
        nextSubSectionView.addSubview(nextSubSectionLabel)
        nextSubSectionView.addSubview(subSectionTitleLabel)
        
        bottomBar.addSubview(nextButton)
        bottomBar.addSubview(previousButton)
        
        addSubview(nextSubSectionView)
        addSubview(bottomBar)
    }
    
    private func setConstraints()
    {
        nextSubSectionView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(snp_top)
            make.leading.equalTo(snp_leading)
            make.trailing.equalTo(snp_trailing)
            make.height.equalTo(70)
        }
        
        nextSubSectionLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(nextSubSectionView.snp_trailing).offset(-10)
            make.centerY.equalTo(nextSubSectionView).offset(-10)
            nextSubSectionView.sizeToFit()
        }
        
        subSectionTitleLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(nextSubSectionView.snp_trailing).offset(-10)
            make.centerY.equalTo(nextSubSectionView).offset(10)
        }
        
        
        bottomBar.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(nextSubSectionView.snp_bottom)
            make.leading.equalTo(snp_leading)
            make.trailing.equalTo(snp_trailing)
            make.bottom.equalTo(snp_bottom)
        }
        
        nextButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(snp_trailing).offset(-15)
            make.centerY.equalTo(bottomBar)
            nextButton.sizeToFit()
        }
        
        previousButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(snp_leading).offset(15)
            make.centerY.equalTo(bottomBar)
            previousButton.sizeToFit()
        }
    }
    
}
