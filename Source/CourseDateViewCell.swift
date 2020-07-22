//
//  CourseDateViewCell.swift
//  CourseDateViewCell
//
//  Created by Zheng-Xiang Ke on 2016/10/20.
//  Copyright © 2016年 Zheng-Xiang Ke. All rights reserved.
//

import UIKit

protocol CourseDateViewCellDelegate {
    func didSelectLinkWith(url: URL)
}

private let imageSize: CGFloat = 14
private let cornerRadius: CGFloat = 5

class CourseDateViewCell: UITableViewCell {
    static let identifier = String(describing: self)
    
    var delegate: CourseDateViewCellDelegate?
    
    private var dark = OEXStyles.shared().neutralDark()
    private var xDark = OEXStyles.shared().neutralXDark()
    private var black = OEXStyles.shared().neutralBlack()
    private var light = OEXStyles.shared().neutralLight()
    private var white = OEXStyles.shared().neutralWhite()
    private var clear = UIColor.clear
    private var yellow = UIColor.systemYellow
    
    private lazy var dateLabel = UILabel()
    private lazy var statusLabel = UILabel()
    
    private lazy var dateAndStatusContainerView = UIView()
    private let statusContainerView = UIView()
    
    private lazy var lockedImageView: UIImageView = {
        let image = Icon.Closed.imageWithFontSize(size: imageSize).withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = OEXStyles().neutralWhite()
        return imageView
    }()
    
    private lazy var dateStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .small, color: xDark)
        style.alignment = .left
        return style
    }()
    
    private lazy var statusStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .italic, size: .xSmall, color: white)
        style.alignment = .center
        return style
    }()
    
    private lazy var titleStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .small, color: xDark)
        style.alignment = .left
        return style
    }()
    
    private lazy var descriptionStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .normal, size: .xSmall, color: dark)
        style.alignment = .left
        return style
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

    var blocks: [CourseDateBlock]? {
        didSet {
            guard let blocks = blocks else { return }
            titleAndDescriptionStackView.subviews.forEach { $0.removeFromSuperview() }
            statusStackView.subviews.forEach { $0.removeFromSuperview() }
            
            if let block = blocks.first {
                dateLabel.attributedText = dateStyle.attributedString(withText: block.dateText)
                updateTimelinePoint(block)
                updateBadge(block)
            }
            
            for block in blocks {
                let titleLabel = TTTAttributedLabel(frame: .zero)
                titleLabel.lineBreakMode = .byWordWrapping
                titleLabel.numberOfLines = 0
                
                titleStyle.color = block.available ? dark : light
                titleLabel.attributedText = titleStyle.attributedString(withText: block.title)
                
                addLink(block, titleLabel)
                
                titleLabel.sizeToFit()
                titleLabel.layoutIfNeeded()
                
                titleAndDescriptionStackView.addArrangedSubview(titleLabel)
                
                addDescriptionLabel(block)
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()        
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
    
    // MARK:- Cell Building
    
    private func updateBadge(_ block: CourseDateBlock) {
            statusLabel.attributedText = statusStyle.attributedString(withText: block.blockStatus.localized)
            statusLabel.textColor = clear
            
            switch block.blockStatus {
            case .today:
                statusContainerView.configure(backgroundColor: yellow, borderColor: clear, borderWith: 0, cornerRadius: cornerRadius)

                statusLabel.textColor = white
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            case .verifiedOnly:
                statusContainerView.configure(backgroundColor: xDark, borderColor: clear, borderWith: 0, cornerRadius: cornerRadius)
                statusLabel.textColor = white
                statusStackView.addArrangedSubview(lockedImageView)
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            case .completed:
                statusContainerView.configure(backgroundColor: white, borderColor: xDark, borderWith: 0.5, cornerRadius: cornerRadius)
                statusLabel.textColor = xDark
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            case .pastDue:
                statusContainerView.configure(backgroundColor: light, borderColor: clear, borderWith: 0, cornerRadius: cornerRadius)
                statusLabel.textColor = xDark
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            case .dueNext:
                statusContainerView.configure(backgroundColor: dark, borderColor: clear, borderWith: 0, cornerRadius: cornerRadius)
                statusLabel.textColor = white
                statusStackView.addArrangedSubview(statusLabel)
                
                break
                
            default:
                statusContainerView.backgroundColor = clear
                
                break
        }
    }
    
    private func addDescriptionLabel(_ block: CourseDateBlock) {
        if block.hasDesription {
            let descriptionLabel = UILabel()
            descriptionLabel.lineBreakMode = .byWordWrapping
            descriptionLabel.numberOfLines = 0
            descriptionLabel.attributedText = descriptionStyle.attributedString(withText: block.description)
            descriptionLabel.sizeToFit()
            descriptionLabel.layoutIfNeeded()
            
            titleAndDescriptionStackView.addArrangedSubview(descriptionLabel)
        }
    }
    
    private func addLink(_ block: CourseDateBlock, _ titleLabel: TTTAttributedLabel) {
        if block.showLink {
            if let url = URL(string: block.link) {
                let range = (block.title as NSString).range(of: block.title)
                
                let linkAttributes: [String: Any] = [
                    NSAttributedString.Key.foregroundColor.rawValue: dark.cgColor,
                    NSAttributedString.Key.underlineStyle.rawValue: true,
                ]
                titleLabel.delegate = self
                titleLabel.linkAttributes = linkAttributes
                titleLabel.activeLinkAttributes = linkAttributes
                titleLabel.addLink(to: url, with: range)
            }
        }
    }
    
    private func updateTimelinePoint(_ block: CourseDateBlock) {
        if block.isInToday {
            timelinePoint.color = yellow
            timelinePoint.diameter = todayTimelinePointDiameter
        } else if block.isInPast {
            if block.blockStatus == .completed {
                timelinePoint.color = white
                timelinePoint.diameter = defaultTimelinePointDiameter
            } else if block.blockStatus == .courseStartDate {
                timelinePoint.color = white
                timelinePoint.diameter = defaultTimelinePointDiameter
            } else if block.blockStatus == .verifiedOnly {
                timelinePoint.color = black
                timelinePoint.diameter = defaultTimelinePointDiameter
            } else {
                timelinePoint.color = light
                timelinePoint.diameter = defaultTimelinePointDiameter
            }
        } else if block.isInFuture {
            timelinePoint.color = black
            timelinePoint.diameter = defaultTimelinePointDiameter
        }
        
        drawTimelineView()
    }
}

extension CourseDateViewCell: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        delegate?.didSelectLinkWith(url: url)
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
