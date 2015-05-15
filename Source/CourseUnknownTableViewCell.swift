//
//  CourseUnknownTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownTableViewCell: UITableViewCell {

    static let identifier = "CourseUnknownTableViewCellIdentifier"
    
    var titleLabel = UILabel()
    var subTitleLabel = UILabel()
    var leftImageButton = UIButton()
    
    var block : CourseBlock? = nil {
        didSet {
            titleLabel.text = block?.name ?? ""
        }
    }
    
    func setStyle(){
        titleLabel.font = UIFont(name: "OpenSans", size: 15.0)
        subTitleLabel.font = UIFont(name: "OpenSans-Light", size: 10.0)
        
        leftImageButton.titleLabel?.font = UIFont.fontAwesomeOfSize(17)
        leftImageButton.setTitle(String.fontAwesomeIconWithName(.Laptop), forState: .Normal)
        leftImageButton.setTitleColor(OEXConfig.iconGreyColor(), forState: .Normal)
    }
    
    func setConstraints(){
        leftImageButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(20)
            make.size.equalTo(CGSizeMake(25, 25))
            
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(-5)
            make.leading.equalTo(leftImageButton).offset(40)
            make.trailing.equalTo(self.snp_trailing).offset(10)
        }
        
        subTitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(14)
            make.leading.equalTo(leftImageButton).offset(40)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)
        self.addSubview(leftImageButton)
        self.addSubview(subTitleLabel)
        subTitleLabel.text = "Sample Subtitle Text for testing"
        setConstraints()
        setStyle()
        //        setNeedsLayout()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
