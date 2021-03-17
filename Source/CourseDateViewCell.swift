//
//  CourseDateViewCell.swift
//  CourseDateViewCell
//
//  Created by Muhammad Umer on 01/07/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

protocol CourseDateViewCellDelegate {
    func didSelectLink(with url: URL)
    func didSetDueNext(with index: Int)
}

private let imageSize: CGFloat = 14

class CourseDateViewCell: UITableViewCell {
    static let identifier = String(describing: self)
    
    var delegate: CourseDateViewCellDelegate?
    
    private lazy var dateStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .bold, size: .large, color: OEXStyles.shared().neutralBlackT())
    }()
    
    private lazy var statusStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .boldItalic, size: .xxSmall, color: OEXStyles.shared().neutralWhite())
        style.alignment = .center
        return style
    }()
    
    private lazy var titleStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralBlack())
        style.lineBreakMode = .byWordWrapping
        return style
    }()
    
    private lazy var descriptionStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralXDark())
    }()
    
    private let dateContainer = UIView()
    private let titleStackContainer = UIView()
    private let titleStackView = TZStackView()
        
    private var timelinePoint = TimelinePoint() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var timeline = Timeline() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var index = -1
    var setDueNext = false
    
    var blocks: [CourseDateBlock]? {
        didSet {
            guard let blocks = blocks else { return }
            setupCell(with: blocks)
        }
    }
    
    private let cornerRadius = 5
    private let lineWidth: CGFloat = 0.5
    private let lineSpacing: CGFloat = 20
    private let todayTimelinePointDiameter: CGFloat = 12
    private let defaultTimelinePointDiameter: CGFloat = 8
    private let textContainerEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 2, right: 0)
    // titleStringCharacterCount and titleStringSecondLineCharacterCount are used to track number of characters in the
    // title inside text view. these are used to determine if space is to be appended or new should be appended
    // if badge status is indivisual and shown after title, as uitextview does not seem to have a way to determine
    // which part of text is on which line.
    private let titleStringCharacterCount = 30
    private let titleStringSecondLineCharacterCount = 45
    
    private var attributedLockImage: NSAttributedString {
        let lockImage = Icon.Closed.imageWithFontSize(size: imageSize).image(with: OEXStyles.shared().neutralWhite())
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = lockImage
        
        let imageOffsetY: CGFloat = -4.0
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: image.size.width, height: image.size.height)
        }
        
        return NSAttributedString(attachment: imageAttachment)
    }
    
    private let attributedSpace = NSMutableAttributedString(string: "  ")
    private let attributedUnicodeSpace = NSAttributedString(string: "\u{00a0}  ")
    private let attributedNewLine = NSMutableAttributedString(string: "\n")
    private let attributedTab = NSMutableAttributedString(string: "\t")
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "CourseDatesViewController:tableview-cell"
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        drawTimelineView()
    }
    
    private func setupViews() {
        titleStackView.spacing = StandardHorizontalMargin / 4
        titleStackView.alignment = .leading
        titleStackView.axis = .vertical
        
        titleStackContainer.addSubview(titleStackView)
        contentView.addSubview(titleStackContainer)
        contentView.addSubview(dateContainer)
    }
    
    private func setupConstrains() {
        dateContainer.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardHorizontalMargin)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin * 5)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardHorizontalMargin + (StandardHorizontalMargin / 2))
        }
        
        titleStackContainer.snp.makeConstraints { make in
            make.top.equalTo(dateContainer.snp.bottom).offset(StandardHorizontalMargin / 2)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin * 5)
            make.trailing.equalTo(contentView).inset(StandardVerticalMargin)
            make.bottom.equalTo(contentView).inset(4)
        }
        
        titleStackView.snp.makeConstraints { make in
            make.edges.equalTo(titleStackContainer)
        }
    }
        
    private func setupCell(with blocks: [CourseDateBlock]) {
        titleStackView.subviews.forEach { $0.removeFromSuperview() }
        
        var isConsolidated = false
        
        if let block = blocks.first {
            if blocks.allSatisfy ({ $0.blockStatus == block.blockStatus }) {
                isConsolidated = true
            }
            addBadge(for: block, isConsolidated: isConsolidated)
            updateTimelinePoint(for: block)
        }
        
        addBadge(for: blocks, isConsolidated: isConsolidated)
    }
    
    private func generateTextView(with attributedString: NSAttributedString) -> (textView: UITextView, textStorage: FillBackgroundTextStorage, layoutManager: FillBackgroundLayoutManager) {
        let textStorage = FillBackgroundTextStorage(attributedString: attributedString)
        let layoutManager = FillBackgroundLayoutManager()
        layoutManager.delegate = self
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: .zero)
        layoutManager.addTextContainer(textContainer)
        
        let textView = UITextView(frame: .zero, textContainer: textContainer)
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainerInset = textContainerEdgeInsets
        textView.textContainer.lineFragmentPadding = .zero
        
        return (textView, textStorage, layoutManager)
    }
    
    private func createBadge(with status: NSAttributedString, isVerified: Bool = false) -> NSAttributedString {
        let badgeStatus = NSMutableAttributedString()
        if isVerified {
            badgeStatus.append(attributedUnicodeSpace)
            badgeStatus.append(attributedLockImage)
        }
        badgeStatus.append(attributedSpace)
        badgeStatus.append(status)
        badgeStatus.append(attributedSpace)
        
        return badgeStatus
    }
    
    // MARK:- Cell Designing
    
    /// Handles case when a block of consolidated dates have same badge status
    private func addBadge(for block: CourseDateBlock, isConsolidated: Bool) {
        let dateText: String
        
        if block.isToday {
            dateText = DateFormatting.format(asWeekDayMonthDateYear: block.blockDate, timeZone: block.timeZone)
        } else {
            dateText = DateFormatting.format(date: DateFormatting.date(withServerString: block.dateString))
        }
        
        let attributedString = dateStyle.attributedString(withText: dateText)
        
        let (textView, textStorage, layoutManager) = generateTextView(with: attributedString)
        
        dateContainer.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalTo(dateContainer)
        }
        
        guard isConsolidated else { return }
        
        var messageText: [NSAttributedString] = [attributedString]
        
        let todayBackgroundColor = OEXStyles.shared().accentBColor()
        let todayForegroundColor = OEXStyles.shared().primaryBaseColor()
        
        var todayAttributedText: NSAttributedString?
        
        if block.isToday {
            let status = statusStyle.attributedString(withText: block.todayText)
            todayAttributedText = createBadge(with: status)
            
            if let todayAttributedText = todayAttributedText {
                messageText.append(attributedSpace)
                messageText.append(todayAttributedText)
            }
        }
        
        var statusBackgroundColor: UIColor = .clear
        var statusForegroundColor: UIColor = .clear
        var statusBorderColor: UIColor = .clear
        
        var statusText: NSAttributedString?
        
        if block.blockStatus != .event && !block.title.isEmpty {
            let status = statusStyle.attributedString(withText: block.blockStatus.localized)
            (statusText, statusBackgroundColor, statusForegroundColor, statusBorderColor) = prepareBadge(for: block, status: status)
            
            if let statusText = statusText {
                messageText.append(attributedSpace)
                messageText.append(statusText)
            }
        }
        
        let statusAttributedString = NSAttributedString.joinInNaturalLayout(attributedStrings: messageText)
        textView.attributedText = statusAttributedString
        
        if let todayAttributedText = todayAttributedText {
            let range = statusAttributedString.string.nsString.range(of: todayAttributedText.string)
            textStorage.drawBackground(range: range, backgroundColor: todayBackgroundColor, foregroundColor: todayForegroundColor)
        }
        
        if let statusText = statusText {
            layoutManager.set(borderColor: statusBorderColor, lineWidth: lineWidth, cornerRadius: cornerRadius)
            let range = statusAttributedString.string.nsString.range(of: statusText.string)
            textStorage.drawBackground(range: range, backgroundColor: statusBackgroundColor, foregroundColor: statusForegroundColor)
        }
    }
    
    /// Handles case when each or some block have different badge status of a single date
    private func addBadge(for blocks: [CourseDateBlock], isConsolidated: Bool) {
        for block in blocks {
            let color = block.isAvailable ? OEXStyles.shared().neutralBlack() : OEXStyles.shared().neutralLight()
            titleStyle.color = color
            let blockTitle = block.assignmentType.isEmpty ? block.title : "\(block.assignmentType): \(block.title)"
            var attributedString = titleStyle.attributedString(withText: blockTitle)
            
            if block.canShowLink, !block.firstComponentBlockID.isEmpty {
                attributedString = attributedString.addLink(on: block.title, value: block.firstComponentBlockID, foregroundColor: color, underline: true)
            }
            
            var messageText: [NSAttributedString] = [attributedString]
            
            let (textView, textStorage, layoutManager) = generateTextView(with: attributedString)
            textView.tintColor = color
            textView.delegate = self

            var statusText: NSAttributedString?
            var statusBackgroundColor: UIColor = .clear
            var statusForegroundColor: UIColor = .clear
            var statusBorderColor: UIColor = .clear
            
            if !isConsolidated {
                if block.blockStatus != .event && !block.title.isEmpty {
                    let status = statusStyle.attributedString(withText: block.blockStatus.localized)
                    (statusText, statusBackgroundColor, statusForegroundColor, statusBorderColor) = prepareBadge(for: block, status: status)
                }
                
                let characterCount = attributedString.string.count
                
                if let statusText = statusText {
                    if !isiPad && characterCount > titleStringCharacterCount && characterCount < titleStringSecondLineCharacterCount {
                        messageText.append(attributedNewLine)
                    } else {
                        messageText.append(attributedTab)
                    }
                    messageText.append(statusText)
                }
            }
            
            let titleAttributedString = NSAttributedString.joinInNaturalLayout(attributedStrings: messageText)
            textView.attributedText = titleAttributedString.setLineSpacing(lineSpacing)
            
            if let statusText = statusText, !isConsolidated {
                layoutManager.set(borderColor: statusBorderColor, lineWidth: lineWidth, cornerRadius: cornerRadius)
                let range = titleAttributedString.string.nsString.range(of: statusText.string)
                textStorage.drawBackground(range: range, backgroundColor: statusBackgroundColor, foregroundColor: statusForegroundColor)
            }
            
            titleStackView.addArrangedSubview(textView)
            
            if block.hasDescription {
                addDescriptionLabel(block)
            }
        }
    }
    
    private func prepareBadge(for block: CourseDateBlock, status: NSAttributedString) -> (statusText: NSAttributedString?, statusBackgroundColor: UIColor, statusForegroundColor: UIColor, statusBorderColor: UIColor) {
        
        var statusText: NSAttributedString?
        var statusBackgroundColor: UIColor = .clear
        var statusForegroundColor: UIColor = .clear
        var statusBorderColor: UIColor = .clear
        
        switch block.blockStatus {
        case .verifiedOnly:
            statusText = createBadge(with: status, isVerified: true)
            
            statusBackgroundColor = OEXStyles.shared().neutralXDark()
            statusForegroundColor = OEXStyles.shared().neutralWhite()
            
            break
            
        case .completed:
            statusText = createBadge(with: status)
            
            statusBackgroundColor = OEXStyles.shared().neutralXLight()
            statusForegroundColor = OEXStyles.shared().neutralXXDark()
            
            break
            
        case .pastDue:
            statusText = createBadge(with: status)
            
            statusBackgroundColor = OEXStyles.shared().neutralBase()
            statusForegroundColor = OEXStyles.shared().neutralBlack()
            
            break
            
        case .dueNext:
            if setDueNext {
                statusText = createBadge(with: status)
                
                statusBackgroundColor = OEXStyles.shared().neutralXDark()
                statusForegroundColor = OEXStyles.shared().neutralWhite()
                
                delegate?.didSetDueNext(with: index)
            } else {
                statusBackgroundColor = .clear
                statusForegroundColor = .clear
            }
            
            break
            
        case .unreleased:
            statusText = createBadge(with: status)
            
            statusBackgroundColor = OEXStyles.shared().neutralWhite()
            statusForegroundColor = OEXStyles.shared().neutralXXDark()
            statusBorderColor = OEXStyles.shared().neutralXDark()
            
            break
            
        default:
            statusBackgroundColor = .clear
            statusForegroundColor = .clear
        }
        
        return (statusText, statusBackgroundColor, statusForegroundColor, statusBorderColor)
    }
    
    /// Adds description to titleStackView if block does contains description
    private func addDescriptionLabel(_ block: CourseDateBlock) {
        let descriptionLabel = UILabel()
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.numberOfLines = 0
        descriptionLabel.attributedText = descriptionStyle.attributedString(withText: block.description)
        descriptionLabel.sizeToFit()
        descriptionLabel.layoutIfNeeded()
        titleStackView.addArrangedSubview(descriptionLabel)
    }
    
    /// Draws timeline View on left side of cell
    private func drawTimelineView() {
        for case let layer as CAShapeLayer in contentView.layer.sublayers ?? [] {
            layer.removeFromSuperlayer()
        }
        
        timelinePoint.position = CGPoint(x: StandardVerticalMargin * 3, y: dateContainer.frame.midY)
        
        timeline.start = CGPoint(x: StandardVerticalMargin * 3, y: 0)
        timeline.middle = CGPoint(x: timeline.start.x, y: timelinePoint.position.y)
        timeline.end = CGPoint(x: timeline.start.x, y: bounds.size.height)
        timeline.draw(view: contentView)
        
        timelinePoint.draw(view: contentView)
    }
    
    /// Updates timeline point color based on appropirate state
    private func updateTimelinePoint(for block: CourseDateBlock) {
        if block.isToday {
            timelinePoint.color = OEXStyles.shared().accentBColor()
            timelinePoint.diameter = todayTimelinePointDiameter
        } else if block.isInPast {
            
            switch block.blockStatus {
            case .courseStartDate, .completed:
                timelinePoint.color = OEXStyles.shared().neutralWhite()
                break
                
            case .verifiedOnly:
                timelinePoint.color = OEXStyles.shared().neutralBlack()
                break
                
            case .pastDue:
                timelinePoint.color = OEXStyles.shared().neutralLight()
                break
                
            default:
                timelinePoint.color = OEXStyles.shared().neutralLight()
                break
            }
            
            timelinePoint.diameter = defaultTimelinePointDiameter
        } else if block.isInFuture {
            timelinePoint.color = OEXStyles.shared().neutralBlack()
            timelinePoint.diameter = defaultTimelinePointDiameter
        }
        
        drawTimelineView()
    }
}

extension CourseDateViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.didSelectLink(with: URL)
        return false
    }
}

extension CourseDateViewCell: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return CGFloat(floorf(Float(glyphIndex) / 100))
    }
    
    func layoutManager(_ layoutManager: NSLayoutManager, paragraphSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return 10
    }
}

fileprivate extension NSAttributedString {
    func setLineSpacing(_ spacing: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = spacing
        paragraphStyle.minimumLineHeight = spacing
        paragraphStyle.paragraphSpacing = spacing
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: string.count))
        return NSAttributedString(attributedString: attributedString)
    }
}

extension String {
    var nsString: NSString {
        return NSString(string: self)
    }
}
