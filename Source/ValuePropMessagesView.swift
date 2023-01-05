//
//  ValuePropMessagesView.swift
//  edX
//
//  Created by Muhammad Umer on 13/07/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

class ValuePropMessagesView: UIView {
    
    private let messages = [
        Strings.ValueProp.infoMessage1,
        Strings.ValueProp.infoMessage2,
        Strings.ValueProp.infoMessage3,
    ]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.estimatedRowHeight = 46
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = false
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
    
    private func setupView() {
        addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    public func height() -> CGFloat {
        tableView.layoutIfNeeded()
        return tableView.contentSize.height
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.isScrollEnabled = tableView.contentSize.height > tableView.frame.size.height
    }
}

extension ValuePropMessagesView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ValuePropMessageCell.identifier, for: indexPath) as! ValuePropMessageCell
        cell.setMessage(message: messages[indexPath.row])

        return cell
    }
}

private class ValuePropMessageCell: UITableViewCell {
    static let identifier = "ValuePropMessageCell"
    private let bulletImageSize: CGFloat = 18
    private let imageContainerSize: CGFloat = 26
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var bulletImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.Check.imageWithFontSize(size: bulletImageSize).image(with: OEXStyles.shared().successBase())
        return imageView
    }()
    
    private lazy var imageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = OEXStyles.shared().successXXLight()
        return view
    }()

    let messageStyle = OEXMutableTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralXXDark())

    private lazy var containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear

        addSubviews()
        setAccessibilityIdentifiers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageContainer.layoutIfNeeded()
        imageContainer.clipsToBounds = true
        imageContainer.layer.cornerRadius = imageContainer.frame.size.width * 0.5
    }
    
    private func addSubviews() {
        contentView.addSubview(containerView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(imageContainer)
        imageContainer.addSubview(bulletImage)
        setConstraints()
    }
    
    func setMessage(message: String) {
        messageLabel.attributedText = messageStyle.attributedString(withText: message).setLineSpacing(4)
    }
    
    private func setAccessibilityIdentifiers() {
        containerView.accessibilityIdentifier = "ValuePropMessageCell:container-view"
        bulletImage.accessibilityIdentifier = "ValuePropMessageCell:bullet-image"
        imageContainer.accessibilityIdentifier = "ValuePropMessageCell:image-container-view"
        messageLabel.accessibilityIdentifier = "ValuePropMessageCell:message-label"
    }
    
    private func setConstraints() {
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
        
        bulletImage.snp.makeConstraints { make in
            make.center.equalTo(imageContainer)
        }
        
        imageContainer.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.leading.equalTo(containerView).offset(StandardVerticalMargin)
            make.width.equalTo(imageContainerSize)
            make.height.equalTo(imageContainerSize)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.leading.equalTo(bulletImage.snp.trailing).offset(StandardVerticalMargin)
            make.trailing.equalTo(containerView).inset(StandardVerticalMargin)
            make.bottom.equalTo(containerView).inset(StandardVerticalMargin)
        }
    }
}
