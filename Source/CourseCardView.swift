//
//  CourseCardView.swift
//  edX
//
//  Created by Jianfeng Qiu on 13/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

@IBDesignable
class CourseCardView: UIView, UIGestureRecognizerDelegate {
    private let arrowHeight = 15.0
    private let verticalMargin = 10
    
    var course: OEXCourse?
    
    private let coverImageView = UIImageView()
    private let container = UIView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let bottomLine = UIView()
    private let bottomTrailingLabel = UILabel()
    private let overlayContainer = UIView()
    
    var tapAction : ((CourseCardView) -> ())?
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .large, color: OEXStyles.shared().neutralBlack())
    }
    private var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .xxxSmall, color: OEXStyles.shared().neutralXDark())
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
    
    @available(iOS 8.0, *)
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        let bundle = Bundle(for: type(of: self))
        coverImageView.image = UIImage(named:"placeholderCourseCardImage", in: bundle, compatibleWith: self.traitCollection)
        titleLabel.attributedText = titleTextStyle.attributedString(withText: "Demo Course")
        detailLabel.attributedText = detailTextStyle.attributedString(withText: "edx | DemoX")
        bottomTrailingLabel.attributedText = detailTextStyle.attributedString(withText: "X Videos, 1.23 MB")
    }
    
    func configureViews() {
        self.backgroundColor = OEXStyles.shared().neutralXLight()
        self.clipsToBounds = true
        self.bottomLine.backgroundColor = OEXStyles.shared().neutralXLight()
        
        self.container.backgroundColor = OEXStyles.shared().neutralWhite().withAlphaComponent(0.85)
        self.coverImageView.backgroundColor = OEXStyles.shared().neutralWhiteT()
        self.coverImageView.contentMode = UIViewContentMode.scaleAspectFill
        self.coverImageView.clipsToBounds = true
        self.coverImageView.hidesLoadingSpinner = true
        
        self.container.accessibilityIdentifier = "Title Bar"
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        self.container.addSubview(bottomTrailingLabel)
        
        self.addSubview(coverImageView)
        self.addSubview(container)
        self.insertSubview(bottomLine, aboveSubview: coverImageView)
        self.addSubview(overlayContainer)
        
        coverImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        coverImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        detailLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: UILayoutConstraintAxis.horizontal)
        detailLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: UILayoutConstraintAxis.horizontal)
        
        self.container.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self)
            make.trailing.equalTo(self).priorityRequired()
            make.bottom.equalTo(self).offset(-OEXStyles.dividerSize())
        }
        self.coverImageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(self.coverImageView.snp_width).multipliedBy(0.533).priorityLow()
            make.bottom.equalTo(self)
        }
        self.detailLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.container).offset(StandardHorizontalMargin)
            make.top.equalTo(self.titleLabel.snp_bottom)
            make.bottom.equalTo(self.container).offset(-verticalMargin)
            make.trailing.equalTo(self.titleLabel)
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

        self.overlayContainer.snp_makeConstraints {make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(container.snp_top)
        }
        
        let tapGesture = UITapGestureRecognizer {[weak self] _ in self?.cardTapped() }
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
    }

    override func updateConstraints() {
        if let accessory = titleAccessoryView {
            accessory.snp_remakeConstraints { make in
                make.trailing.equalTo(container).offset(-StandardHorizontalMargin)
                make.centerY.equalTo(container)
            }
        }

        self.titleLabel.snp_remakeConstraints { (make) -> Void in
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            if let accessory = titleAccessoryView {
                make.trailing.lessThanOrEqualTo(accessory).offset(-StandardHorizontalMargin)
            }
            else {
                make.trailing.equalTo(container).offset(-StandardHorizontalMargin)
            }
            make.top.equalTo(container).offset(verticalMargin)
        }

        super.updateConstraints()
    }

    var titleAccessoryView : UIView? = nil {
        willSet {
            titleAccessoryView?.removeFromSuperview()
        }
        didSet {
            if let accessory = titleAccessoryView {
                container.addSubview(accessory)
            }
            updateConstraints()
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return tapAction != nil
    }
    
    var titleText : String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.attributedText = titleTextStyle.attributedString(withText: newValue)
            updateAcessibilityLabel()
        }
    }
    
    var detailText : String? {
        get {
            return self.detailLabel.text
        }
        set {
            self.detailLabel.attributedText = detailTextStyle.attributedString(withText: newValue)
            updateAcessibilityLabel()
        }
    }
    
    var bottomTrailingText : String? {
        get {
            return self.bottomTrailingLabel.text
        }
        
        set {
            self.bottomTrailingLabel.attributedText = detailTextStyle.attributedString(withText: newValue)
            self.bottomTrailingLabel.isHidden = !(newValue != nil && !newValue!.isEmpty)
            updateAcessibilityLabel()
        }
    }
    
    var coverImage : RemoteImage? {
        get {
            return self.coverImageView.remoteImage
        }
        set {
            self.coverImageView.remoteImage = newValue
        }
    }
    
    private func cardTapped() {
        self.tapAction?(self)
    }
    
    func wrapTitleLabel() {
        self.titleLabel.numberOfLines = 3
        self.titleLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.titleLabel.minimumScaleFactor = 0.5
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.layoutIfNeeded()
    }
    
    @discardableResult func updateAcessibilityLabel()-> String {
        var accessibilityString = ""
        
        if let title = titleText {
            accessibilityString = title
        }
        
        if let text = detailText {
         let formatedDetailText = text.replacingOccurrences(of: "|", with: "")
            accessibilityString = "\(accessibilityString),\(Strings.accessibilityBy) \(formatedDetailText)"
        }
        
        if let bottomText = bottomTrailingText {
            accessibilityString = "\(accessibilityString), \(bottomText)"
        }
        
        accessibilityLabel = accessibilityString
        return accessibilityString
    }
    
    func addCenteredOverlay(view : UIView) {
        addSubview(view)
        view.snp_makeConstraints {make in
            make.center.equalTo(overlayContainer)
        }
    }
}
