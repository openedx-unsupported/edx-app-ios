//
//  CourseDashboardCourseInfoCell.swift
//  edX
//
//  Created by Jianfeng Qiu on 13/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseDashboardCourseInfoCell: UITableViewCell {

    static let identifier = "CourseDashboardCourseInfoCellIdentifier"
    
    //TODO: all these should be adjusted once the final UI is ready
    let LABEL_SIZE_HEIGHT = 20.0
    let CONTAINER_SIZE_HEIGHT = 60.0
    let CONTAINER_MARGIN_BOTTOM = 15.0
    let TEXT_MARGIN = 10.0
    let SEPARATORLINE_SIZE_HEIGHT = 1.0
    
    var course: OEXCourse?
    
    var coverImage = UIImageView()
    var container = UIView()
    var titleLabel = UILabel()
    var detailLabel = UILabel()
    var bottomLine = UIView()
    
    var titleTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 18.0)
        style.color = OEXStyles.sharedStyles()?.neutralBlack()
        return style
    }
    var detailTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 11.0)
        style.color = OEXStyles.sharedStyles()?.neutralDark()
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureViews()
        self.selectionStyle = UITableViewCellSelectionStyle.None
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, notification: "ImageDownloadComplete") { [weak self] (notification, observer, removable) -> Void in
            self?.setImageForImageView(notification)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViews() {
        self.contentView.backgroundColor = OEXStyles.sharedStyles()?.neutralXXLight()
        self.bottomLine.backgroundColor = OEXStyles.sharedStyles()?.neutralXXLight()
        
        self.container.backgroundColor = OEXStyles.sharedStyles()?.neutralWhite()
        self.coverImage.backgroundColor = OEXStyles.sharedStyles()?.neutralWhiteT()
        self.coverImage.contentMode = UIViewContentMode.ScaleAspectFit
        
        titleTextStyle.applyToLabel(self.titleLabel)
        detailTextStyle.applyToLabel(self.detailLabel)
        
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        
        self.contentView.addSubview(coverImage)
        self.contentView.addSubview(container)
        self.contentView.addSubview(bottomLine)
        
        self.container.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self.contentView)
            make.trailing.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-CONTAINER_MARGIN_BOTTOM)
            make.height.equalTo(CONTAINER_SIZE_HEIGHT)
        }
        self.coverImage.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.contentView)
            make.leading.equalTo(self.contentView)
            make.bottom.equalTo(self.container.snp_top)
            make.trailing.equalTo(self.contentView)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.container).offset(TEXT_MARGIN)
            make.trailing.equalTo(self.container).offset(TEXT_MARGIN)
            make.top.equalTo(self.container).offset(TEXT_MARGIN)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
        self.detailLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.container).offset(TEXT_MARGIN)
            make.trailing.equalTo(self.container).offset(TEXT_MARGIN)
            make.top.equalTo(self.titleLabel.snp_bottom)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
        self.bottomLine.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView)
            make.trailing.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView)
            make.height.equalTo(SEPARATORLINE_SIZE_HEIGHT)
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
