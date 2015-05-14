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
    
    var nextSubSectionView = UIView()
    var nextSubSectionLabel = UILabel()
    var subSectionTitleLabel = UILabel()
    var bottomBar = UIView()
    var nextButton = UIButton()
    var previousButton = UIButton()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubviews()
        setConstraints()
        setStyles()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStyles()
    {
        nextSubSectionView.backgroundColor = OEXConfig.footerGreyColor()
        
        nextSubSectionLabel.font = UIFont(name: "OpenSans", size: 12.0)
        nextSubSectionLabel.textColor = OEXConfig.textGreyColor()
        
        subSectionTitleLabel.font = UIFont(name: "OpenSans", size: 13.0)
        
        nextButton.setTitle("NEXT", forState: .Normal)
        nextButton.setTitleColor(OEXConfig.textBlueColor(), forState: .Normal)
        nextButton.titleLabel?.font = UIFont(name: "OpenSans-Semibold", size: 13.0)
        
        previousButton.setTitle("PREVIOUS", forState: .Normal)
        previousButton.setTitleColor(OEXConfig.textBlueColor(), forState: .Normal)
        previousButton.titleLabel?.font = UIFont(name: "OpenSans-Semibold", size: 13.0)
        
        nextSubSectionLabel.text = "Next Subsection"
        subSectionTitleLabel.text = "Homework 1: Your First Grade"
    }
    
    func addSubviews()
    {
        backgroundView = UIView(frame: CGRectMake(0, 0, 320.0, 100.0))
        backgroundView?.backgroundColor = UIColor.whiteColor()
        
        nextSubSectionView.addSubview(nextSubSectionLabel)
        nextSubSectionView.addSubview(subSectionTitleLabel)
        
        bottomBar.addSubview(nextButton)
        bottomBar.addSubview(previousButton)
        
        addSubview(nextSubSectionView)
        addSubview(bottomBar)
    }
    
    func setConstraints()
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
