//
//  CourseDateViewCell.swift
//  CourseDateViewCell
//
//  Created by Muhammad Umer on 01/07/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

protocol CourseDateViewCellDelegate {
    func didSelectLinkWith(with url: URL)
    func didSetDueNext()
}

private let imageSize: CGFloat = 14
private let cornerRadius: CGFloat = 5

class CourseDateViewCell: UITableViewCell {
    static let identifier = String(describing: self)
    
    var delegate: CourseDateViewCellDelegate?
        
    private lazy var dateLabel = UILabel()
    private lazy var statusLabel = UILabel()
    
    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.numberOfLines = 0
        return descriptionLabel
    }()
    
    private lazy var dateAndStatusContainerView = UIView()
    private let statusContainerView = UIView()
    
    private lazy var lockedImageView: UIImageView = {
        let image = Icon.Closed.imageWithFontSize(size: imageSize).withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = OEXStyles.shared().neutralWhite()
        return imageView
    }()
    
    private lazy var dateStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().neutralXDark())
    }()
    
    private lazy var statusStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .semiBold, size: .small, color: OEXStyles.shared().neutralWhite())
        style.alignment = .center
        return style
    }()
    
    private lazy var titleStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().neutralBlack())
        style.lineBreakMode = .byWordWrapping
        return style
    }()
    
    private lazy var descriptionStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralDark())
    }()
    
    private let titleAndDescriptionStackView = TZStackView()
    private let dateAndStatusContainerStackView = TZStackView()
    private let statusStackView = TZStackView()
    
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
    
    private var minimumViewWidth = 60
    private var todayTimelinePointDiameter: CGFloat = 12
    private var defaultTimelinePointDiameter: CGFloat = 8
    
    var setDueNextOnThisBlock = false
    var userTimeZone: String?
    
    var blocks: [DateBlock]? {
        didSet {
            guard let blocks = blocks else { return }
            titleAndDescriptionStackView.subviews.forEach { $0.removeFromSuperview() }
            statusStackView.subviews.forEach { $0.removeFromSuperview() }
            
            if let block = blocks.first {
                let dateText = DateFormatting.format(asWeekDayMonthDateYear: block.blockDate, timeZoneIdentifier: userTimeZone)
                dateLabel.attributedText = dateStyle.attributedString(withText: dateText)
                updateTimelinePoint(block)
                updateBadge(block)
            }
            
            for block in blocks {
                let titleTextView = UITextView(frame: .zero)
                titleTextView.isUserInteractionEnabled = true
                titleTextView.isScrollEnabled = false
                titleTextView.isEditable = false
                titleTextView.textContainerInset = .zero
                titleTextView.textContainer.lineFragmentPadding = .zero
                
                let color = block.isAvailable ? OEXStyles.shared().neutralBlack() : OEXStyles.shared().neutralLight()
                titleStyle.color = color
                titleTextView.tintColor = color
                var attributedString = titleStyle.attributedString(withText: block.title)
                                
                if block.canShowLink, let url = URL(string: block.link) {
                    attributedString = attributedString.addLink(on: block.title, value: url, foregroundColor: color, underline: true)
                    titleTextView.delegate = self
                }

                titleTextView.attributedText = attributedString
                titleTextView.sizeToFit()

                titleAndDescriptionStackView.addArrangedSubview(titleTextView)
                
                if block.hasDescription {
                    addDescriptionLabel(block)
                }
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "CourseDatesViewController:table-cell"
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        drawTimelineView()
    }
    
    private func drawTimelineView() {
        for layer in contentView.layer.sublayers ?? [] {
            if layer is CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }
                
        timelinePoint.position = CGPoint(x: (StandardVerticalMargin * 3), y: dateAndStatusContainerView.frame.midY)
        
        timeline.start = CGPoint(x: (StandardVerticalMargin * 3), y: 0)
        timeline.middle = CGPoint(x: timeline.start.x, y: timelinePoint.position.y)
        timeline.end = CGPoint(x: timeline.start.x, y: bounds.size.height)
        timeline.draw(view: contentView)
        
        timelinePoint.draw(view: contentView)
    }
    
    private func setupViews() {
        titleAndDescriptionStackView.spacing = (StandardHorizontalMargin / 4)
        titleAndDescriptionStackView.alignment = .leading
        titleAndDescriptionStackView.axis = .vertical
        
        dateAndStatusContainerStackView.addArrangedSubview(dateLabel)
        statusContainerView.addSubview(statusStackView)
        dateAndStatusContainerStackView.addArrangedSubview(statusContainerView)
        
        statusStackView.alignment = .center
        statusStackView.axis = .horizontal
        statusStackView.spacing = (StandardHorizontalMargin / 2)
        
        dateAndStatusContainerStackView.alignment = .center
        dateAndStatusContainerStackView.axis = .horizontal
        dateAndStatusContainerStackView.spacing = (StandardHorizontalMargin)
        
        contentView.addSubview(titleAndDescriptionStackView)
        contentView.addSubview(dateAndStatusContainerView)
        dateAndStatusContainerView.addSubview(dateAndStatusContainerStackView)
    }
    
    private func setupConstrains() {
        statusContainerView.snp.makeConstraints { make in
            make.height.equalTo(StandardHorizontalMargin + 4)
            make.width.greaterThanOrEqualTo(minimumViewWidth)
        }
        
        dateAndStatusContainerView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardHorizontalMargin)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin * 5)
            make.height.equalTo(StandardHorizontalMargin + 4)
            make.width.greaterThanOrEqualTo(minimumViewWidth)
        }
        
        statusStackView.snp.makeConstraints { make in
            make.leading.equalTo(statusContainerView).offset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(statusContainerView).inset(StandardHorizontalMargin / 2)
            make.top.equalTo(statusContainerView)
            make.bottom.equalTo(statusContainerView)
        }
        
        dateAndStatusContainerStackView.snp.makeConstraints { make in
            make.edges.equalTo(dateAndStatusContainerView)
        }
        
        titleAndDescriptionStackView.snp.makeConstraints { make in
            make.top.equalTo(dateAndStatusContainerView.snp.bottom).offset(StandardHorizontalMargin / 2)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin * 5)
            make.trailing.equalTo(contentView).inset(StandardVerticalMargin)
            make.bottom.equalTo(contentView).inset(4)
        }
    }
    
    // MARK:- Cell Information Designing
    
    /// Designs the badge/pill with appropirate state of block
    private func updateBadge(_ block: DateBlock) {
            statusLabel.attributedText = statusStyle.attributedString(withText: block.blockStatus.localized)
            statusLabel.textColor = .clear
            
            switch block.blockStatus {
            case .today:
                statusContainerView.configure(backgroundColor: .systemYellow, borderColor: .clear, borderWith: 0, cornerRadius: cornerRadius)
                statusLabel.textColor = OEXStyles.shared().neutralXDark()
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            case .verifiedOnly:
                statusContainerView.configure(backgroundColor: OEXStyles.shared().neutralXDark(), borderColor: .clear, borderWith: 0, cornerRadius: cornerRadius)
                statusLabel.textColor = OEXStyles.shared().neutralWhite()
                statusStackView.addArrangedSubview(lockedImageView)
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            case .completed:
                statusContainerView.configure(backgroundColor: OEXStyles.shared().neutralXXLight(), borderColor: .clear, borderWith: 0, cornerRadius: cornerRadius)
                statusLabel.textColor = OEXStyles.shared().neutralXDark()
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            case .pastDue:
                statusContainerView.configure(backgroundColor: OEXStyles.shared().neutralLight(), borderColor: .clear, borderWith: 0, cornerRadius: cornerRadius)
                statusLabel.textColor = OEXStyles.shared().neutralXDark()
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            case .dueNext:
                if setDueNextOnThisBlock {
                    statusContainerView.configure(backgroundColor: OEXStyles.shared().neutralDark(), borderColor: .clear, borderWith: 0, cornerRadius: cornerRadius)
                    statusLabel.textColor = OEXStyles.shared().neutralWhite()
                    statusStackView.addArrangedSubview(statusLabel)
                    delegate?.didSetDueNext()
                } else {
                    statusContainerView.backgroundColor = .clear
                }
                
                break
                
            case .unreleased:
                statusContainerView.configure(backgroundColor: OEXStyles.shared().neutralWhite(), borderColor: OEXStyles.shared().neutralXDark(), borderWith: 0.5, cornerRadius: cornerRadius)
                statusLabel.textColor = OEXStyles.shared().neutralXDark()
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            default:
                statusContainerView.backgroundColor = .clear
                
                break
        }
    }
    
    /// Adds description to titleAndDescriptionStackView if block does contains description
    private func addDescriptionLabel(_ block: DateBlock) {
        descriptionLabel.attributedText = descriptionStyle.attributedString(withText: block.description)
        descriptionLabel.sizeToFit()
        descriptionLabel.layoutIfNeeded()
        
        titleAndDescriptionStackView.addArrangedSubview(descriptionLabel)
    }
    
    /// Updates timeline point color based on appropirate state
    private func updateTimelinePoint(_ block: DateBlock) {
        if block.isToday {
            timelinePoint.color = .systemYellow
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
        delegate?.didSelectLinkWith(with: URL)
        return false
    }
}

fileprivate extension UIView {
    func configure(backgroundColor: UIColor, borderColor: UIColor , borderWith: CGFloat, cornerRadius: CGFloat) {
        layer.backgroundColor = backgroundColor.cgColor
        layer.borderWidth = borderWith
        layer.borderColor = borderColor.cgColor
        layer.cornerRadius = cornerRadius
    }
}
