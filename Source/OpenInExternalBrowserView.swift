//
//  OpenInExternalBrowserView.swift
//  edX
//
//  Created by Saeed Bashir on 4/21/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

protocol OpenInExternalBrowserViewDelegate: AnyObject {
    func openInExternalBrower()
}

class OpenInExternalBrowserView: UIView, UITextViewDelegate {
    private let container = UIView()
    private let messageLabel = UILabel()
    private let button = UIButton()

    private var browserIcon: NSAttributedString {
        let icon = Icon.OpenInBrowser.imageWithFontSize(size: 18).image(with: OEXStyles.shared().neutralXDark())
        let attachment = NSTextAttachment()
        attachment.image = icon

        let imageOffsetY: CGFloat = -4.0
        if let image = attachment.image {
            attachment.bounds = CGRect(x: 0, y: imageOffsetY, width: image.size.width, height: image.size.height)
        }

        return NSAttributedString(attachment: attachment)
    }

    weak var delegate: OpenInExternalBrowserViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {

        messageLabel.numberOfLines = 0
        container.backgroundColor = OEXStyles.shared().infoXXLight()

        container.addSubview(messageLabel)
        container.addSubview(button)
        addSubview(container)

        container.snp.remakeConstraints { make in
            make.edges.equalTo(self)
        }

        messageLabel.snp.remakeConstraints { make in
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin)
            make.centerY.equalTo(container)
        }

        button.snp.remakeConstraints{ make in
            make.edges.equalTo(container)
        }

        let textStyle = OEXTextStyle(weight : .normal, size: .base, color: OEXStyles.shared().neutralXDark())
        let message = textStyle.attributedString(withText: Strings.OpenInExternalBrowser.message)

        let clickableStyle = OEXTextStyle(weight : .normal, size: .base, color: OEXStyles.shared().neutralXDark())
        let clickableText = clickableStyle.attributedString(withText: Strings.OpenInExternalBrowser.openInBroswer).addUnderline(foregroundColor: OEXStyles.shared().neutralXDark())
        let formattedText = NSAttributedString.joinInNaturalLayout(
            attributedStrings: [message, clickableText, browserIcon])
        messageLabel.attributedText = formattedText

        button.oex_addAction({[weak self] (action) in
            self?.delegate?.openInExternalBrower()
        }, for: .touchUpInside)

        setAccessibilityIdentifiers()
    }

    private func setAccessibilityIdentifiers() {
        container.accessibilityIdentifier = "OpenInExternalBrowserView:container-view"
        messageLabel.accessibilityIdentifier = "OpenInExternalBrowserView:message-label"
        button.accessibilityIdentifier = "OpenInExternalBrowserView:open-in-browser-button"
    }
}
