//
//  OEXCourseDashboardCourseInfoCell.swift
//  edX
//
//  Created by Qiu, Jianfeng on 5/8/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class OEXCourseDashboardCourseInfoCell: UITableViewCell {
    
    static let identifier = "CourseDashboardCourseInfoCellIdentifier"
    
    static let titleTextColor = UIColor.blackColor()
    static let titleTextFont = UIFont(name: "HelveticaNeue", size: CGFloat(18))
    static let detailTextColor = UIColor(red: 100/255.0, green: 100/255.0, blue: 100/255.0, alpha: 1.0)
    static let detailTextFont = UIFont(name: "HelveticaNeue", size: CGFloat(11))
    
    var course: OEXCourse?
    
    var coverImage = UIImageView()
    var container = UIView()
    var titleLabel = UILabel()
    var detailLabel = UILabel()
    var bottomLine = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureViews()
        self.selectionStyle = UITableViewCellSelectionStyle.None
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setImageForImageView:", name: "ImageDownloadComplete", object: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func configureViews() {
        self.contentView.backgroundColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
        self.bottomLine.backgroundColor = UIColor(red: 224.0/255.0, green: 224.0/255.0, blue: 224.0/255.0, alpha: 1.0)
        
        self.container.backgroundColor = UIColor(red: 247/255.0, green: 247/255.0, blue: 247/255.0, alpha: 1.0)
        self.coverImage.backgroundColor = UIColor.whiteColor()
        self.coverImage.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.titleLabel.textColor = OEXCourseDashboardCourseInfoCell.titleTextColor
        self.titleLabel.font = OEXCourseDashboardCourseInfoCell.titleTextFont
        self.detailLabel.textColor = OEXCourseDashboardCourseInfoCell.detailTextColor
        self.detailLabel.font = OEXCourseDashboardCourseInfoCell.detailTextFont
        
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        
        self.contentView.addSubview(coverImage)
        self.contentView.addSubview(container)
        self.contentView.addSubview(bottomLine)
        
        self.container.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.contentView).offset(0)
            make.right.equalTo(self.contentView).offset(0)
            make.bottom.equalTo(self.contentView).offset(-15)
            make.height.equalTo(60)
        }
        self.coverImage.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.contentView).offset(0)
            make.left.equalTo(self.contentView).offset(0)
            make.bottom.equalTo(self.container.snp_top).offset(0)
            make.right.equalTo(self.contentView).offset(0)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.container).offset(10)
            make.right.equalTo(self.container).offset(10)
            make.top.equalTo(self.container).offset(10)
            make.height.equalTo(20)
        }
        self.detailLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.container).offset(10)
            make.right.equalTo(self.container).offset(10)
            make.top.equalTo(self.titleLabel.snp_bottom).offset(0)
            make.height.equalTo(20)
        }
        self.bottomLine.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.contentView).offset(0)
            make.right.equalTo(self.contentView).offset(0)
            make.bottom.equalTo(self.contentView).offset(0)
            make.height.equalTo(1)
        }
        
    }
    
    func setCoverImage() {
        if let courseInCell = self.course {
            let imgUrlString: String? = OEXConfig.sharedConfig().apiHostURL() + courseInCell.course_image_url
            if let imgUrl = imgUrlString {
                OEXImageCache.sharedInstance().getImage(imgUrl)
            }
        }
    }
    
    func setImageForImageView(notification: NSNotification) {
        let dictObj = notification.object as! NSDictionary
        let image: UIImage? = dictObj.objectForKey("image") as? UIImage
        let downloadImageUrl: String? = dictObj.objectForKey("image_url") as? String
        
        if let downloadedImage = image {
            if let courseInCell = self.course {
                let imgUrlString: String? = OEXConfig.sharedConfig().apiHostURL() + courseInCell.course_image_url
                if imgUrlString == downloadImageUrl {
                    self.coverImage.image = downloadedImage
                }
            }
        }
    }
    

}
