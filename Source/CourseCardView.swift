//
//  CourseCardView.swift
//  edX
//
//  Created by Jianfeng Qiu on 13/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

@IBDesignable
class CourseCardView: UIView {
    private let arrowHeight = 15.0
    private let verticalMargin = 10
    
    var course: OEXCourse?
    
    private let coverImage = UIImageView()
    private let container = UIView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let bottomLine = UIView()
    private let bottomTrailingLabel = UILabel()
    
    var tapAction : (CourseCardView -> ())?
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Large, color: OEXStyles.sharedStyles().neutralBlack())
    }
    private var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .XXXSmall, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    private func setup() {
        configureViews()
        
        accessibilityTraits = UIAccessibilityTraitStaticText
        accessibilityHint = Strings.accessibilityShowsCourseContent

    }
    
    override init(frame : CGRect) {
        super.init(frame : frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    var networkManager : NetworkManager?
    
    @available(iOS 8.0, *)
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        let bundle = NSBundle(forClass: self.dynamicType)
        coverImage.image = UIImage(named:"Splash_map", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        titleLabel.attributedText = titleTextStyle.attributedStringWithText("Demo Course")
        detailLabel.attributedText = detailTextStyle.attributedStringWithText("edx | DemoX")
        bottomTrailingLabel.attributedText = detailTextStyle.attributedStringWithText("X Videos, 1.23 MB")
    }
    
    func configureViews() {
        self.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        self.clipsToBounds = true
        self.bottomLine.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        self.container.backgroundColor = OEXStyles.sharedStyles().neutralWhite().colorWithAlphaComponent(0.85)
        self.coverImage.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        self.coverImage.contentMode = UIViewContentMode.ScaleAspectFill
        self.coverImage.clipsToBounds = true
        self.coverImage.hidesLoadingSpinner = true
        
        self.container.accessibilityIdentifier = "Title Bar"
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        self.container.addSubview(bottomTrailingLabel)
        
        self.addSubview(coverImage)
        self.addSubview(container)
        self.insertSubview(bottomLine, aboveSubview: coverImage)
        
        coverImage.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        coverImage.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Vertical)
        detailLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: UILayoutConstraintAxis.Horizontal)
        detailLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, forAxis: UILayoutConstraintAxis.Horizontal)
        
        self.container.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self)
            make.trailing.equalTo(self).priorityRequired()
            make.bottom.equalTo(self).offset(-OEXStyles.dividerSize())
        }
        self.coverImage.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(self.coverImage.snp_width).multipliedBy(0.533).priorityLow()
            make.bottom.equalTo(self)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.container).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(self.container).offset(-StandardHorizontalMargin)
            make.top.equalTo(self.container).offset(verticalMargin)
        }
        self.detailLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.container).offset(StandardHorizontalMargin)
            make.top.equalTo(self.titleLabel.snp_bottom)
            make.bottom.equalTo(self.container).offset(-verticalMargin)
        }
        self.bottomLine.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.top.equalTo(self.container.snp_bottom)
        }
        
        self.bottomTrailingLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(detailLabel)
            make.trailing.equalTo(self.container).offset(-StandardHorizontalMargin)
        }
        
        self.addGestureRecognizer(UITapGestureRecognizer {[weak self] _ in self?.cardTapped() })
    }
    
    var titleText : String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.attributedText = titleTextStyle.attributedStringWithText(newValue)
            updateAcessibilityLabel()
        }
    }
    
    var detailText : String? {
        get {
            return self.detailLabel.text
        }
        set {
            self.detailLabel.attributedText = detailTextStyle.attributedStringWithText(newValue)
            updateAcessibilityLabel()
        }
    }
    
    var bottomTrailingText : String? {
        get {
            return self.bottomTrailingLabel.text
        }
        
        set {
            self.bottomTrailingLabel.attributedText = detailTextStyle.attributedStringWithText(newValue)
            self.bottomTrailingLabel.hidden = !(newValue != nil && !newValue!.isEmpty)
            updateAcessibilityLabel()
        }
    }
    
    private func cardTapped() {
        self.tapAction?(self)
    }
    
    private func updateAcessibilityLabel() {
        accessibilityLabel = "\(titleText),\(detailText),\(bottomTrailingText)"
    }
    
    private func imageURL() -> String? {
        if let courseInCell = self.course, relativeURLString = courseInCell.course_image_url {
            let baseURL = OEXConfig.sharedConfig().apiHostURL()
            return NSURL(string: relativeURLString, relativeToURL: baseURL)?.absoluteString
        }
        return nil
    }
    
    func setCoverImage() {
        let placeholder = UIImage(named: "Splash_map")
        coverImage.image = placeholder
        if let networkManager = networkManager, imageURL = imageURL() where !imageURL.isEmpty {
            coverImage.remoteImage = RemoteImageImpl(url: imageURL, networkManager: networkManager, placeholder: placeholder)
        }
    }
}
