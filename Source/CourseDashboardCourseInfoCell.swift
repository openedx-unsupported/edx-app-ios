//
//  CourseDashboardCourseInfoCell.swift
//  edX
//

/**
Copyright (c) 2015 Qualcomm Education, Inc.
All rights reserved.


Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

* Neither the name of Qualcomm Education, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

import UIKit

class CourseDashboardCourseInfoCell: UITableViewCell {

    static let identifier = "CourseDashboardCourseInfoCellIdentifier"
    
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
            make.left.equalTo(self.contentView)
            make.right.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-15)
            make.height.equalTo(60)
        }
        self.coverImage.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.contentView)
            make.left.equalTo(self.contentView)
            make.bottom.equalTo(self.container.snp_top)
            make.right.equalTo(self.contentView)
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
            make.top.equalTo(self.titleLabel.snp_bottom)
            make.height.equalTo(20)
        }
        self.bottomLine.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.contentView)
            make.right.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView)
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
