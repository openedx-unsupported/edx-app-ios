//
//  CourseCardView.swift
//  edX
//
//  Created by Jianfeng Qiu on 13/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let defaultCoverImageAspectRatio:CGFloat = 0.533

@IBDesignable
class CourseCardView: UIView, UIGestureRecognizerDelegate {
    private let arrowHeight = 15.0
    private let verticalMargin = 10
    private let coverImageView = UIImageView()
    private let container = UIView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let bottomLine = UIView()
    private let overlayContainer = UIView()

    var course: OEXCourse?
    var tapAction : ((CourseCardView) -> ())?
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .semiBold, size: .xLarge, color: OEXStyles.shared().neutralXDark())
    }
    private var dateTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .small, color: OEXStyles.shared().neutralDark())
    }
    private var coverImageAspectRatio : CGFloat {
        // Let the placeholder image aspect ratio determine the course card image aspect ratio.
        guard let placeholder = UIImage(named:"placeholderCourseCardImage") else {
            return defaultCoverImageAspectRatio
        }
        return placeholder.size.height / placeholder.size.width
    }
    
    private func setupView() {
        configureViews()
        
        accessibilityTraits = UIAccessibilityTraitStaticText
        accessibilityHint = Strings.accessibilityShowsCourseContent
    }
    
    override init(frame : CGRect) {
        super.init(frame : frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        let bundle = Bundle(for: type(of: self))
        coverImageView.image = UIImage(named:"placeholderCourseCardImage", in: bundle, compatibleWith: traitCollection)
        titleLabel.attributedText = titleTextStyle.attributedString(withText: "Demo Course")
        dateLabel.attributedText = dateTextStyle.attributedString(withText: "edx | DemoX")
    }
    
    func configureViews() {
        backgroundColor = OEXStyles.shared().neutralXLight()
        clipsToBounds = true
        bottomLine.backgroundColor = OEXStyles.shared().neutralXLight()
        
        container.backgroundColor = OEXStyles.shared().neutralWhite().withAlphaComponent(0.85)
        coverImageView.backgroundColor = OEXStyles.shared().neutralWhiteT()
        coverImageView.contentMode = UIViewContentMode.scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.hidesLoadingSpinner = true
        
        container.accessibilityIdentifier = "Title Bar"
        container.addSubview(titleLabel)
        container.addSubview(dateLabel)
        
        addSubview(coverImageView)
        addSubview(container)
        insertSubview(bottomLine, aboveSubview: coverImageView)
        addSubview(overlayContainer)
        
        coverImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        coverImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        dateLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: UILayoutConstraintAxis.horizontal)
        dateLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: UILayoutConstraintAxis.horizontal)
        
        container.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self).priority(.required)
            make.bottom.equalTo(self).offset(-OEXStyles.dividerSize())
        }
        coverImageView.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(coverImageView.snp.width).multipliedBy(coverImageAspectRatio).priority(.low)
            make.bottom.equalTo(self)
        }
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(container).offset(-verticalMargin)
            make.trailing.equalTo(titleLabel)
        }
        bottomLine.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.top.equalTo(container.snp.bottom)
        }
        
        overlayContainer.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(container.snp.top)
        }
        
        let tapGesture = UITapGestureRecognizer {[weak self] _ in self?.cardTapped() }
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    override func updateConstraints() {
        if let accessory = titleAccessoryView {
            accessory.snp.remakeConstraints { make in
                make.trailing.equalTo(container).offset(-StandardHorizontalMargin)
                make.centerY.equalTo(container)
            }
        }
        
        titleLabel.snp.remakeConstraints { make in
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
            return titleLabel.text
        }
        set {
            titleLabel.attributedText = titleTextStyle.attributedString(withText: newValue)
            updateAcessibilityLabel()
        }
    }
    
    var dateText : String? {
        get {
            return dateLabel.text
        }
        set {
            dateLabel.attributedText = dateTextStyle.attributedString(withText: newValue)
            updateAcessibilityLabel()
        }
    }
    
    var coverImage : RemoteImage? {
        get {
            return coverImageView.remoteImage
        }
        set {
            coverImageView.remoteImage = newValue
        }
    }
    
    private func cardTapped() {
        tapAction?(self)
    }
    
    func wrapTitleLabel() {
        titleLabel.numberOfLines = 3
        titleLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.adjustsFontSizeToFitWidth = true
        layoutIfNeeded()
    }
    
    @discardableResult func updateAcessibilityLabel()-> String {
        var accessibilityString = ""
        
        if let title = titleText {
            accessibilityString = title
        }
        
        if let text = dateText {
            let formateddateText = text.replacingOccurrences(of: "|", with: "")
            accessibilityString = "\(accessibilityString),\(Strings.accessibilityBy) \(formateddateText)"
        }
        
        accessibilityLabel = accessibilityString
        return accessibilityString
    }
    
    func addCenteredOverlay(view : UIView) {
        addSubview(view)
        view.snp.makeConstraints { make in
            make.center.equalTo(overlayContainer)
        }
    }
}

extension CourseCardView {
    static func cardHeight(leftMargin: CGFloat = 0, rightMargin: CGFloat = 0) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.size.width
        var height: CGFloat = 0
        let screenHeight = UIScreen.main.bounds.size.height
        let halfScreenHeight = (screenHeight / 2.0) - (leftMargin + rightMargin)
        let ratioedHeight = screenWidth * defaultCoverImageAspectRatio
        height = CGFloat(Int(halfScreenHeight > ratioedHeight ? ratioedHeight : halfScreenHeight))
        return height
    }
}

