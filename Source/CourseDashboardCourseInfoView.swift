//
//  CourseDashboardCourseInfoView.swift
//  edX
//
//  Created by Jianfeng Qiu on 13/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

//TODO: (MK) replace OEXFrontTableViewCell with this
/** The Course Card View */
@IBDesignable
class CourseDashboardCourseInfoView: UIView {
    //TODO: all these should be adjusted once the final UI is ready
    private let LABEL_SIZE_HEIGHT = 20.0
    private let CONTAINER_SIZE_HEIGHT = 60.0
    private let CONTAINER_MARGIN_BOTTOM = 15.0
    private let TEXT_MARGIN = 10.0
    private let SEPARATORLINE_SIZE_HEIGHT = 1.0
    
    var course: OEXCourse?
    
    private let coverImage = UIImageView()
    private let container = UIView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let bottomLine = UIView()
    
    var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Large, color: OEXStyles.sharedStyles().neutralBlack())
    }
    var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    override init(frame : CGRect) {
        super.init(frame : frame)
        configureViews()
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXImageDownloadCompleteNotification) { [weak self] (notification, observer, _) -> Void in
            observer.setImageForImageView(notification)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        coverImage.image = UIImage(named: "Splash_map")
        titleLabel.text = "Demo Course"
    }
    
    func configureViews() {
        self.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        self.clipsToBounds = true
        self.bottomLine.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        self.container.backgroundColor = OEXStyles.sharedStyles().neutralWhite().colorWithAlphaComponent(0.85)
        self.coverImage.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        self.coverImage.contentMode = UIViewContentMode.ScaleAspectFill
        self.coverImage.clipsToBounds = true
        
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        
        self.addSubview(coverImage)
        self.addSubview(container)
        self.insertSubview(bottomLine, aboveSubview: coverImage)
        
        self.container.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self).offset(-CONTAINER_MARGIN_BOTTOM)
            make.height.equalTo(CONTAINER_SIZE_HEIGHT)
        }
        self.coverImage.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
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
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.top.equalTo(self.container.snp_bottom)
        }
    }
    
    var titleText : String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.attributedText = titleTextStyle.attributedStringWithText(newValue)
        }
    }
    
    var detailText : String? {
        get {
            return self.detailLabel.text
        }
        set {
            self.detailLabel.attributedText = detailTextStyle.attributedStringWithText(newValue)
        }
    }
    
    private func imageURL() -> String? {
        if let courseInCell = self.course, relativeURLString = courseInCell.course_image_url {
            let baseURL = NSURL(string:OEXConfig.sharedConfig().apiHostURL() ?? "")
            return NSURL(string: relativeURLString, relativeToURL: baseURL)?.absoluteString
        }
        return nil
    }
    
    func setCoverImage() {
        if let imageURL = imageURL() {
            OEXImageCache.sharedInstance().getImage(imageURL)
        } else {
            coverImage.image = UIImage(named: "Splash_map")
        }
    }
    
    func setImageForImageView(notification: NSNotification) {
        let dictObj = notification.object as! NSDictionary
        let image: UIImage? = dictObj.objectForKey("image") as? UIImage
        let downloadImageUrl: String? = dictObj.objectForKey("image_url") as? String
        
        if let downloadedImage = image, courseInCell = self.course, imageURL = imageURL()  {
            if imageURL == downloadImageUrl {
                self.coverImage.image = downloadedImage
                let ar = downloadedImage.size.height / downloadedImage.size.width
                self.coverImage.snp_makeConstraints({ (make) -> Void in
                    make.height.equalTo(self.coverImage.snp_width).multipliedBy(ar)
                })
            }
        }
    }
}
