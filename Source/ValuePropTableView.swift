//
//  ValuePropTableView.swift
//  edX
//
//  Created by Muhammad Umer on 13/07/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

class ValuePropTableView: UIView {
    
    private let infoMessages = [
        Strings.ValueProp.infoMessage1,
        Strings.ValueProp.infoMessage2,
        Strings.ValueProp.infoMessage3,
        Strings.ValueProp.infoMessage4(platformName: OEXConfig.shared().platformName())
    ]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
        tableView.register(ValuePropMessageCell.self, forCellReuseIdentifier: ValuePropMessageCell.identifier)
        tableView.accessibilityIdentifier = "ValuePropDetailView:tableView"
        return tableView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
}

extension ValuePropTableView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ValuePropMessageCell.identifier, for: indexPath) as! ValuePropMessageCell
        cell.setMessage(message: infoMessages[indexPath.row])
        cell.backgroundColor = .clear
        return cell
    }
}

private class ValuePropMessageCell: UITableViewCell {
    static let identifier = "ValuePropMessageCell"
    private let bulletImageSize: CGFloat = 24
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var bulletImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.Check.imageWithFontSize(size: bulletImageSize).image(with: OEXStyles.shared().successBase())
        imageView.backgroundColor = OEXStyles.shared().successXXLight()
        return imageView
    }()
    
    private lazy var containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
        setAccessibilityIdentifiers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bulletImage.layoutIfNeeded()
        bulletImage.clipsToBounds = true
        bulletImage.layer.cornerRadius = bulletImage.frame.size.width * 0.5
    }
    
    private func addSubviews() {
        contentView.addSubview(containerView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(bulletImage)
        setConstraints()
    }
    
    func setMessage(message: String) {
        let messageStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryDarkColor())
        messageLabel.attributedText = messageStyle.attributedString(withText: message)
    }
    
    private func setAccessibilityIdentifiers() {
        containerView.accessibilityIdentifier = "ValuePropMessageCell:container-view"
        bulletImage.accessibilityIdentifier = "ValuePropMessageCell:bullet-image"
        bulletImage.accessibilityIdentifier = "ValuePropMessageCell:message-label"
    }
    
    private func setConstraints() {
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
        
        bulletImage.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.leading.equalTo(containerView).offset(StandardVerticalMargin)
            make.width.equalTo(bulletImageSize)
            make.height.equalTo(bulletImageSize)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.leading.equalTo(bulletImage.snp.trailing).offset(StandardVerticalMargin)
            make.trailing.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(StandardVerticalMargin)
        }
    }
}
