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
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        return view
    }()
    
    let stackView = TZStackView()
    
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
    
    var status: String? {
        didSet {
            let style = OEXMutableTextStyle(weight: .bold, size: .xxSmall, color: OEXStyles.shared().neutralWhite())
            style.alignment = .center
            statusLabel.attributedText = style.attributedString(withText: status ?? "")
        }
    }
    
    var titleText: String? {
        didSet {
            guard let title = titleText else {
                stackView.removeArrangedSubview(titleLabel)
                return
            }
            let style = OEXMutableTextStyle(weight: .bold, size: .small, color: OEXStyles.shared().neutralDark())
            style.alignment = .left
            titleLabel.attributedText = style.attributedString(withText: title)
            titleLabel.sizeToFit()
            titleLabel.layoutIfNeeded()
        }
    }
    
    var descriptionText: String? {
        didSet {
            guard let description = descriptionText else {
                stackView.removeArrangedSubview(descriptionLabel)
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
        containerView.backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.sizeToFit()
        descriptionLabel.sizeToFit()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func draw(_ rect: CGRect) {
        for layer in contentView.layer.sublayers ?? [] {
            if layer is CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }
        
        dateLabel.sizeToFit()
        titleLabel.sizeToFit()
        
        timelinePoint.position = CGPoint(x: (StandardVerticalMargin * 3), y: dateLabel.frame.origin.y + dateLabel.intrinsicContentSize.height / 2)
        
        timeline.start = CGPoint(x: (StandardVerticalMargin * 3), y: 0)
        timeline.middle = CGPoint(x: timeline.start.x, y: timelinePoint.position.y)
        timeline.end = CGPoint(x: timeline.start.x, y: bounds.size.height)
        timeline.draw(view: contentView)
        
        timelinePoint.draw(view: contentView)
    }
    
    private func setupViews() {
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.alignment = .leading
        stackView.axis = .vertical
        
        contentView.addSubview(stackView)
        contentView.addSubview(containerView)
        contentView.addSubview(dateLabel)
        containerView.addSubview(statusLabel)
    }
    
    private func setupConstrains() {
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardHorizontalMargin)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin * 5)
            make.height.equalTo(StandardHorizontalMargin + 4)
            make.width.greaterThanOrEqualTo(minLabelWidth)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardHorizontalMargin)
            make.leading.equalTo(dateLabel.snp.trailing).offset(StandardVerticalMargin)
            make.height.equalTo(StandardHorizontalMargin + 4)
            make.width.greaterThanOrEqualTo(minLabelWidth)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView)
            make.bottom.equalTo(containerView)
            make.leading.equalTo(containerView).offset(StandardVerticalMargin)
            make.trailing.equalTo(containerView).inset(StandardVerticalMargin)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(4)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin * 5)
            make.trailing.equalTo(contentView).inset(StandardVerticalMargin)
            make.bottom.equalTo(contentView).inset(4)
        }
    }
}
