//
//  CourseOutlineItemView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol CourseBlockContainerCell {
    var block : CourseBlock? { get }
    func applyStyle(style : TableCellStyle)
}

private let TitleOffsetTrailing = -10
private let SubtitleOffsetTrailing = -10
private let IconSize = CGSize(width: 25, height: 25)
private let CellOffsetTrailing: CGFloat = 25
private let TitleOffsetCenterY = -10
private let TitleOffsetLeading = 40
private let SubtitleOffsetCenterY = 10
private let DownloadCountOffsetTrailing = -2
private let SubtitleLeadingOffset = 20

private let SmallIconSize: CGFloat = 17

public class CourseOutlineItemView: UIView {
    static let detailFontStyle = OEXTextStyle(weight: .normal, size: .small, color : OEXStyles.shared().neutralBlack())
    
    private let fontStyle = OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralBlackT())
    private let boldFontStyle = OEXTextStyle(weight: .bold, size: .small, color : OEXStyles.shared().neutralBlack())
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let leadingImageButton = UIButton(type: UIButton.ButtonType.system)
    private let subtitleLeadingImageView = UIImageView()
    private let trailingContainer = UIView()
    private let separator = UIView()
    
    private var shouldShowLeadingView: Bool = true
    
    var isSectionOutline = false {
        didSet {
            refreshTrailingViewConstraints()
        }
    }
    
    var shouldShowSubtitleLeadingImageView = true
    
    private var trailingIcon: Icon?
    private let attributedUnicodeSpace = NSAttributedString(string: "\u{3000}")
    
    private let labelTrailingImageColor = OEXStyles.shared().neutralXDark()
        
    private var attributedTrailingImage: NSAttributedString {
        let image = trailingIcon?.imageWithFontSize(size: SmallIconSize).image(with: labelTrailingImageColor)
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        
        let imageOffsetY: CGFloat = -4.0
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: image.size.width, height: image.size.height)
        }
        
        return NSAttributedString(attachment: imageAttachment)
    }
    
    public var isGraded: Bool? {
        get {
            return !subtitleLeadingImageView.isHidden
        }
        set {
            subtitleLeadingImageView.isHidden = !(newValue ?? false)
            setNeedsUpdateConstraints()
        }
    }
    
    var leadingIconColor: UIColor? {
        get {
            return leadingImageButton.tintColor
        }
        set {
            leadingImageButton.tintColor = newValue
        }
    }
    
    func image(for icon: Icon?) -> UIImage? {
        return icon?.imageWithFontSize(size: SmallIconSize)
    }
    
    init() {
        super.init(frame: .zero)
        
        shouldShowSubtitleLeadingImageView = true
        
        leadingImageButton.tintColor = .clear
        leadingImageButton.accessibilityTraits = .image
        leadingImageButton.isAccessibilityElement = false
        
        subtitleLeadingImageView.image = Icon.Graded.imageWithFontSize(size: SmallIconSize)
        subtitleLeadingImageView.tintColor = OEXStyles.shared().primaryBaseColor()
        
        isGraded = false
        addSubviews()
        setConstraints()
        setAccessibility()
        setAccessibilityIdentifiers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "CourseOutlineItemView:view"
        titleLabel.accessibilityIdentifier = "CourseOutlineItemView:title-label"
        subtitleLabel.accessibilityIdentifier = "CourseOutlineItemView:subtitle-label"
        leadingImageButton.accessibilityIdentifier = "CourseOutlineItemView:leading-image-button"
        subtitleLeadingImageView.accessibilityIdentifier = "CourseOutlineItemView:check-image-view"
        trailingContainer.accessibilityIdentifier = "CourseOutlineItemView:trailing-container-view"
        trailingView.accessibilityIdentifier = "CourseOutlineItemView:trailing-view"
    }
    
    func setTitleText(title: String, elipsis: Bool = true) {
        if !elipsis {
            titleLabel.attributedText = fontStyle.attributedString(withText: title)
        } else {
            let formattedText = getFormattedText(text: title)
            let attributedTitle = fontStyle.attributedString(withText: formattedText)
            let attributedString = NSMutableAttributedString()
            attributedString.append(attributedTitle)
            attributedString.append(attributedUnicodeSpace)
            attributedString.append(attributedTrailingImage)
            titleLabel.attributedText = attributedString
            setConstraints()
        }

        titleLabel.accessibilityLabel = title
    }

    func setCompletionAccessibility(completion: Bool = false) {

        titleLabel.accessibilityLabel = completion ? "\(titleLabel.accessibilityLabel ?? ""), \(Strings.Accessibility.completed)" : titleLabel.accessibilityLabel
    }
    
    func formattedDueDateString(asMonthDay date: NSDate?) -> String {
        guard let date = date else { return "" }
        
        let dateString = DateFormatting.format(asMinHourOrMonthDayYearString: date)
        let dateOrder = DateFormatting.compareTwoDates(fromDate: DateFormatting.getDate(withFormat: "MMM dd, yyyy", date: Date()), toDate: DateFormatting.getDate(withFormat: "MMM dd, yyyy", date: date as Date))
        let formattedDateString = (dateOrder == .orderedSame) ? Strings.courseDueDateSameDay(dueDate: dateString, timeZone: DateFormatting.timeZoneAbbriviation()) : Strings.courseDueDate(dueDate: dateString)
        return formattedDateString
    }
    
    func getAttributedString(withBlockType type: CourseBlockType?, withText text: String) -> NSAttributedString {
        guard let blockType = type, case CourseBlockType.Section = blockType else {
            return CourseOutlineItemView.detailFontStyle.attributedString(withText: text)
        }
        
        return boldFontStyle.attributedString(withText: text)
    }
    
    func setDetailText(title : String, dueDate: String? = "", blockType: CourseBlockType?, videoSize: String? = "", underline: Bool = false) {
        
        var attributedStrings = [NSAttributedString]()
        var attributedString = getAttributedString(withBlockType: blockType, withText: title)
        
        if underline {
            attributedString = attributedString.addUnderline()
        }
        
        attributedStrings.append(attributedString)
        
        if isGraded == true {
            let formattedDateString = formattedDueDateString(asMonthDay: DateFormatting.date(withServerString: dueDate))
            attributedStrings.append(CourseOutlineItemView.detailFontStyle.attributedString(withText: formattedDateString))
        }
        subtitleLabel.tintColor = boldFontStyle.color
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.6
        subtitleLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
        setConstraints(with: blockType)
    }
    
    func setContentIcon(icon: Icon?, color: UIColor) {
        shouldShowLeadingView = true
        let image = icon?.imageWithFontSize(size: SmallIconSize)
        leadingImageButton.setImage(image, for: .normal)
        leadingImageButton.tintColor = color
        if let accessibilityText = icon?.accessibilityText {
            leadingImageButton.accessibilityLabel = accessibilityText
        }
        setConstraints()
    }
    
    func setSeperatorColor(color: UIColor) {
        separator.backgroundColor = color
    }
    
    func hideLeadingView() {
        shouldShowLeadingView = false
        setConstraints()
    }
        
    func hideTrailingView() {
        trailingView.isHidden = true
    }
    
    func setTitleTrailingIcon(icon: Icon?) {
        trailingIcon = icon
        setConstraints()
    }
    
    private func setConstraints(with blockType: CourseBlockType? = nil) {
        leadingImageButton.isHidden = !shouldShowLeadingView
        
        leadingImageButton.snp.remakeConstraints { make in
            make.centerY.equalTo(titleLabel)
            let offsetMargin = shouldShowLeadingView ? StandardHorizontalMargin / 2 : 0
            make.leading.equalTo(self).offset(offsetMargin)
            make.size.equalTo(IconSize)
        }
        
        let shouldOffsetTitle = !(subtitleLabel.text?.isEmpty ?? true)
        titleLabel.snp.remakeConstraints { make in
            let titleOffset = shouldOffsetTitle ? TitleOffsetCenterY : 0
            make.centerY.equalTo(self).offset(titleOffset)
            if shouldShowLeadingView {
                make.leading.equalTo(leadingImageButton.snp.trailing).offset(StandardHorizontalMargin / 2)
            } else {
                make.leading.equalTo(self).offset(StandardHorizontalMargin)
            }
            make.trailing.lessThanOrEqualTo(trailingContainer.snp.leading).offset(TitleOffsetTrailing)
        }
        
        subtitleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(self).offset(SubtitleOffsetCenterY)
            
            if let blockType = blockType {
                if case CourseBlockType.Section = blockType {
                    make.leading.equalTo(subtitleLeadingImageView.snp.leading).offset(SubtitleLeadingOffset)
                } else {
                    make.leading.equalTo(subtitleLeadingImageView.snp.leading).offset(0)
                }
            } else if shouldShowSubtitleLeadingImageView {
                make.leading.equalTo(subtitleLeadingImageView.snp.leading).offset(SubtitleLeadingOffset)
            } else {
                make.leading.equalTo(subtitleLeadingImageView.snp.leading).offset(0)
            }
            make.trailing.lessThanOrEqualTo(self).offset(-StandardHorizontalMargin)
        }
        
        separator.snp.remakeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(1)
        }
    }
    
    private func addSubviews() {
        addSubview(leadingImageButton)
        addSubview(trailingContainer)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(subtitleLeadingImageView)
        addSubview(separator)
        
        // For performance only add the static constraints once
        
        subtitleLeadingImageView.snp.remakeConstraints { make in
            make.bottom.equalTo(subtitleLabel)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(trailingContainer.snp.leading).offset(5)
            make.size.equalTo(CGSize(width: SmallIconSize, height: SmallIconSize))
        }
        
        subtitleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(self).offset(SubtitleOffsetCenterY)
            
            if subtitleLeadingImageView.isHidden {
                make.leading.equalTo(subtitleLeadingImageView.snp.leading).offset(SubtitleLeadingOffset)
            } else {
                make.leading.equalTo(subtitleLeadingImageView.snp.leading).offset(0)
            }
        }
        
        refreshTrailingViewConstraints()
    }
    
    private func refreshTrailingViewConstraints() {
        trailingContainer.snp.remakeConstraints { make in
            make.trailing.equalTo(self.snp.trailing).inset(isSectionOutline ? 10 : CellOffsetTrailing)
            make.centerY.equalTo(self)
            make.width.equalTo(SmallIconSize * 2)
        }
    }
    
    var trailingView = UIView() {
        didSet {
            oldValue.removeFromSuperview()
            
            trailingView.isHidden = false
            trailingContainer.addSubview(trailingView)
            
            refreshTrailingViewConstraints()
            
            trailingView.snp.remakeConstraints { make in
                // required to prevent long titles from compressing this
                make.edges.equalTo(trailingContainer).priority(.required)
            }
            setNeedsLayout()
        }
    }
    
    public override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    private func setAccessibility() {
        subtitleLabel.isAccessibilityElement = false
    }
    
    private func getFormattedText(text: String) -> String {
        var formattedText = truncatedText(with: text)
        if text != formattedText {
            formattedText = formattedText + "..."
        }
        
        return formattedText
    }
    
    private func truncatedText(with text: String) -> String {
        let width = text.widthOfString(using: titleLabel.font)
        let offset = CGFloat(StandardHorizontalMargin * 7) + (IconSize.width * 2)
        if width > UIScreen.main.bounds.width - offset {
            return truncatedText(with: String(text.dropLast()))
        }
        return text
    }
}

fileprivate extension String {
    func widthOfString(using font: UIFont) -> CGFloat {
        let size = self.size(withAttributes: [.font: font])
        return size.width
    }
}
