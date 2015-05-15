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

// TODO : Make a property indexPath for the table view cell and then make a delegate which takes the TouchUpInside event as "downloadButtonPressed(indexPath : NSIndexPath)" method in the delegate.

class CourseVideoTableViewCell: UITableViewCell {

    static let identifier = "CourseVideoTableViewCellIdentifier"
    var titleLabel = UILabel()
    var timeLabel = UILabel()
    var leftImageButton = UIButton()
    var downloadButton = UIButton()
    var block : CourseBlock? = nil {
        didSet {
            titleLabel.text = block?.name ?? ""
        }
    }
    var state : CourseVideoState {
        didSet {
            switch state{
            case .NotViewed:
                leftImageButton.setTitleColor(OEXStyles.sharedStyles()?.primaryBaseColor(), forState: .Normal)
            case .PartiallyViewed:
                leftImageButton.setTitleColor(OEXStyles.sharedStyles()?.neutralBase(), forState: .Normal)
            case .Completed:
                leftImageButton.setTitleColor(OEXStyles.sharedStyles()?.utilityBase(), forState: .Normal)
            case .None:
                leftImageButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        state = CourseVideoState.None
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
        setConstraints()
        setStyle()
    }

    private func addSubviews() {
        self.addSubview(titleLabel)
        self.addSubview(leftImageButton)
        self.addSubview(downloadButton)
        self.addSubview(timeLabel)
    }
    private func setStyle(){
        titleLabel.font = UIFont(name: "OpenSans", size: 15.0)
        timeLabel.font = UIFont(name: "OpenSans-Light", size: 10.0)
        
        leftImageButton.titleLabel?.font = UIFont.fontAwesomeOfSize(17)
        leftImageButton.setTitle(String.fontAwesomeIconWithName(.Film), forState: .Normal)
        leftImageButton.setTitleColor(OEXStyles.sharedStyles()?.primaryBaseColor(), forState: .Normal)
        
        downloadButton.titleLabel?.font = UIFont.fontAwesomeOfSize(13)
        downloadButton.setTitle(String.fontAwesomeIconWithName(.ArrowDown), forState: .Normal)
        downloadButton.setTitleColor(OEXStyles.sharedStyles()?.neutralBase(), forState: .Normal)
        
        timeLabel.text = "15:51" // TEMPORARY
        
    }
    
    private func setConstraints(){
        leftImageButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(20)
            make.size.equalTo(CGSizeMake(25, 25))
            
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(-5)
            make.leading.equalTo(leftImageButton).offset(40)
            make.trailing.equalTo(downloadButton.snp_leading).offset(10)
        }
        
        timeLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(12)
            make.leading.equalTo(leftImageButton).offset(40)
        }
        
        downloadButton.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(CGSizeMake(15, 15))
            make.trailing.equalTo(self.snp_trailing).offset(-10)
            make.centerY.equalTo(self)
        }

    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
