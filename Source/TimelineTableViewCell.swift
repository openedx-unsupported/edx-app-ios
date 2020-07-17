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
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var dateAndStatusContainerView = UIView()
    let statusContainerView: UIView = {
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
    
    let titleAndDescriptionStackView = TZStackView()
    let dateAndStatusContainerStackView = TZStackView()
    let statusStackView = TZStackView()
    
    var timelinePoint = TimelinePoint() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var timeline = Timeline() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var dateText: String? {
        didSet {
            let style = OEXMutableTextStyle(weight: .bold, size: .small, color: OEXStyles.shared().neutralDark())
            style.alignment = .left
            dateLabel.attributedText = style.attributedString(withText: dateText ?? "")
        }
    }
    
    var dateStatus: CourseStatusType? {
        didSet {
            guard let status = dateStatus else {
                dateAndStatusContainerView.backgroundColor = .clear
                dateAndStatusContainerStackView.removeFromSuperview()
                dateAndStatusContainerView.removeFromSuperview()
                return
            }
            
            switch status {
            case .verifiedOnly:
                statusContainerView.backgroundColor = .black
                statusLabel.textColor = .white
                break
                                
            case .today:
                timelinePoint.color = .systemYellow
                timelinePoint.diameter = 12
                drawTimelineView()
                statusContainerView.backgroundColor = .systemYellow
                lockedImageView.removeFromSuperview()
                statusLabel.textColor = OEXStyles.shared().neutralLight()
                break
                
            case .courseExpiredDate:
                statusContainerView.backgroundColor = .clear
                statusLabel.textColor = .red
                print(".courseExpiredDate")
                break
            default:
                statusContainerView.backgroundColor = .clear
                break
            }
            
            let style = OEXMutableTextStyle(weight: .italic, size: .xSmall, color: OEXStyles.shared().neutralWhite())
            style.alignment = .center
            statusLabel.attributedText = style.attributedString(withText: status.localized)
        }
    }
    
    var titleAndLink: [[String : String]]? {
        didSet {
            guard let titleAndLink = titleAndLink else {
                titleAndDescriptionStackView.addArrangedSubview(descriptionLabel)
                return
            }
            
            for item in titleAndLink {
                for (title, link) in item {
                    let titleLabel = TTTAttributedLabel(frame: .zero)
                    titleLabel.lineBreakMode = .byWordWrapping
                    titleLabel.numberOfLines = 0
                    
                    let color = OEXStyles.shared().neutralDark()
                    
                    let style = OEXMutableTextStyle(weight: .bold, size: .small, color: color)
                    style.alignment = .left
                    titleLabel.attributedText = style.attributedString(withText: title)
                    
                    if !link.isEmpty {
                        if let url = URL(string: link) {
                            let range = (title as NSString).range(of: title)
                            
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
                }
            }
            
            titleAndDescriptionStackView.addArrangedSubview(descriptionLabel)
        }
    }
    
    var descriptionText: String? {
        didSet {
            guard let description = descriptionText else {
                titleAndDescriptionStackView.removeArrangedSubview(descriptionLabel)
                return
            }
            let style = OEXMutableTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralDark())
            style.alignment = .left
            descriptionLabel.attributedText = style.attributedString(withText: description)
            descriptionLabel.sizeToFit()
            descriptionLabel.layoutIfNeeded()
        }
    }
    
    private var minLabelWidth = 60
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //titleLabel.sizeToFit()
        descriptionLabel.sizeToFit()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
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
        //titleLabel.sizeToFit()
        
        timelinePoint.position = CGPoint(x: (StandardVerticalMargin * 3), y: dateAndStatusContainerView.frame.midY)
        
        timeline.start = CGPoint(x: (StandardVerticalMargin * 3), y: 0)
        timeline.middle = CGPoint(x: timeline.start.x, y: timelinePoint.position.y)
        timeline.end = CGPoint(x: timeline.start.x, y: bounds.size.height)
        timeline.draw(view: contentView)
        
        timelinePoint.draw(view: contentView)
    }
    
    private func setupViews() {
        titleAndDescriptionStackView.spacing = (StandardHorizontalMargin / 2)
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
            make.width.greaterThanOrEqualTo(minLabelWidth)
        }
        
        dateAndStatusContainerView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardHorizontalMargin)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin * 5)
            make.height.equalTo(StandardHorizontalMargin + 4)
            make.width.greaterThanOrEqualTo(minLabelWidth)
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
