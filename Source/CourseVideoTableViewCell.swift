//
//  CourseVideoTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 12/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


public enum CourseVideoState : Int {
    case NotViewed = 0
    case PartiallyViewed
    case Completed
    case None
}



class CourseVideoTableViewCell: UITableViewCell {

    static let identifier = "CourseVideoTableViewCellIdentifier"
    
    var state : CourseVideoState {
        didSet {
            switch state{
            case .NotViewed:
                leftImageButton.setTitleColor(OEXConfig.iconBlueColor(), forState: .Normal)
            case .PartiallyViewed:
                leftImageButton.setTitleColor(OEXConfig.iconGreyColor(), forState: .Normal)
            case .Completed:
                leftImageButton.setTitleColor(OEXConfig.iconGreenColor(), forState: .Normal)
            case .None:
                leftImageButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            }
        }
    }
    var label : UILabel = UILabel()
    var leftImageButton : UIButton  = UIButton()
    
    var block : CourseBlock? = nil {
        didSet {
            label.text = block?.name ?? ""
        }
    }
    
    func setStyle(){
        self.label.font = UIFont(name: "OpenSans-Light", size: 14)
        self.leftImageButton.titleLabel?.font = UIFont.fontAwesomeOfSize(20)
        self.leftImageButton.setTitle(String.fontAwesomeIconWithName(.Film), forState: .Normal)
        self.leftImageButton.setTitleColor(OEXConfig.iconBlueColor(), forState: .Normal)
    }
    
    func setConstraints(){
        leftImageButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(20)
            make.size.equalTo(CGSizeMake(25, 25))
            
        }
        
        label.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.leading.equalTo(leftImageButton).offset(40)
            
        }
        label.sizeToFit()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.state = CourseVideoState.None
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(label)
        self.addSubview(leftImageButton)
        setConstraints()
        setStyle()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
