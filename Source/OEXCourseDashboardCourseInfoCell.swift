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
