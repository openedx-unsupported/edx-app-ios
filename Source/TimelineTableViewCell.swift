//
//  TimelineTableViewCell.swift
//  TimelineTableViewCell
//
//  Created by Zheng-Xiang Ke on 2016/10/20.
//  Copyright © 2016年 Zheng-Xiang Ke. All rights reserved.
//

import UIKit

class TimelineTableViewCell: UITableViewCell {
    static let identifier = String(describing: self)
    
    private lazy var dateLabel = UILabel()
    private lazy var statusLabel = UILabel()
    
    private lazy var dateAndStatusContainerView = UIView()
    private let statusContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        return view
    }()
    
    private lazy var lockedImageView: UIImageView = {
        let image = Icon.Closed.imageWithFontSize(size: 14).withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = OEXStyles().neutralWhite()
        return imageView
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
    
    var blocks: [CourseDateBlock]? {
        didSet {
            guard let blocks = blocks else { return }
            titleAndDescriptionStackView.subviews.forEach { $0.removeFromSuperview() }
            
            if let firstItem = blocks.first {
                
                if firstItem.isInToday {
                    timelinePoint.color = .systemYellow
                    timelinePoint.diameter = 12
                } else if firstItem.isInPast {
                    timelinePoint.color = .white
                    timelinePoint.diameter = 8
                } else if firstItem.isInFuture {
                    timelinePoint.color = .black
                    timelinePoint.diameter = 8
                }
                drawTimelineView()
                
                let dateStyle = OEXMutableTextStyle(weight: .bold, size: .small, color: OEXStyles.shared().neutralDark())
                dateStyle.alignment = .left
                dateLabel.attributedText = dateStyle.attributedString(withText: firstItem.dateText)
                
                let statusStyle = OEXMutableTextStyle(weight: .italic, size: .xSmall, color: OEXStyles.shared().neutralWhite())
                statusStyle.alignment = .center
                statusLabel.attributedText = statusStyle.attributedString(withText: firstItem.blockStatus.localized)
                statusLabel.textColor = .white
                
                switch firstItem.blockStatus {
                case .today:
                    statusContainerView.backgroundColor = .systemYellow
                    lockedImageView.removeFromSuperview()
                    break
                    
                case .verifiedOnly:
                    statusContainerView.backgroundColor = .black
                    break
                case .completed:
                    statusContainerView.backgroundColor = .gray
                    lockedImageView.removeFromSuperview()
                    break
                    
                case .pastDue:
                    statusContainerView.backgroundColor = .gray
                    lockedImageView.removeFromSuperview()
                    break
                    
                case .dueNext:
                    statusContainerView.backgroundColor = .gray
                    lockedImageView.removeFromSuperview()
                    break
                    
                default:
                    statusContainerView.backgroundColor = .clear
                    break
                }
            }
            
            for block in blocks {
                let titleLabel = TTTAttributedLabel(frame: .zero)
                titleLabel.lineBreakMode = .byWordWrapping
                titleLabel.numberOfLines = 0
                
                let color = OEXStyles.shared().neutralDark()
                let titleStyle = OEXMutableTextStyle(weight: .bold, size: .small, color: color)
                titleStyle.alignment = .left
                titleLabel.attributedText = titleStyle.attributedString(withText: block.title)
                
                if !block.link.isEmpty && block.learnerHasAccess {
                    if let url = URL(string: block.link) {
                        let range = (block.title as NSString).range(of: block.title)
                        
                        let linkAttributes: [String: Any] = [
                            NSAttributedString.Key.foregroundColor.rawValue: color.cgColor,
                            NSAttributedString.Key.underlineStyle.rawValue: true,
                        ]
                        
                        titleLabel.linkAttributes = linkAttributes
                        titleLabel.activeLinkAttributes = linkAttributes
                        titleLabel.addLink(to: url, with: range)
                    }
                }
                
                titleLabel.sizeToFit()
                titleLabel.layoutIfNeeded()
                
                titleAndDescriptionStackView.addArrangedSubview(titleLabel)
                
                if !block.description.isEmpty {
                    let descriptionLabel = UILabel()
                    descriptionLabel.lineBreakMode = .byWordWrapping
                    descriptionLabel.numberOfLines = 0
                    
                    let descriptionStyle = OEXMutableTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralDark())
                    descriptionStyle.alignment = .left
                    descriptionLabel.attributedText = descriptionStyle.attributedString(withText: block.descriptionField)
                    descriptionLabel.sizeToFit()
                    descriptionLabel.layoutIfNeeded()
                    
                    titleAndDescriptionStackView.addArrangedSubview(descriptionLabel)
                }
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
    
    public func drawTimelineView() {
        for layer in contentView.layer.sublayers ?? [] {
            if layer is CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }
        
        dateLabel.sizeToFit()
        
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
        
        statusStackView.addArrangedSubview(lockedImageView)
        statusStackView.addArrangedSubview(statusLabel)
        
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
            make.leading.equalTo(statusContainerView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(statusContainerView).inset(StandardHorizontalMargin)
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
}
