//
//  OpenInExternalBrowserView.swift
//  edX
//
//  Created by Saeed Bashir on 4/21/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

protocol OpenInExternalBrowserViewDelegate: class {
    func openInExternalBrower()
}

class OpenInExternalBrowserView: UIView, UITextViewDelegate {
    let container = UIView()
    let messageLabel = UILabel()
    let button = UIButton()

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

        let textStyle : OEXTextStyle = OEXTextStyle(weight : .normal, size: .small, color: OEXStyles.shared().neutralXDark())
        let message = textStyle.attributedString(withText: Strings.OpenInExternalBrowser.message)


        let clickAbleStyle : OEXTextStyle = OEXTextStyle(weight : .normal, size: .base, color: OEXStyles.shared().neutralXDark())
        let clickAbleText = clickAbleStyle.attributedString(withText: Strings.OpenInExternalBrowser.openInBroswer).addUnderline(foregroundColor: OEXStyles.shared().neutralXDark())
        let icon = Icon.OpenInBrowser.attributedTextWithStyle(style: clickAbleStyle)

        let formattedText = NSAttributedString.joinInNaturalLayout(
            attributedStrings: [message, clickAbleText, icon])

        messageLabel.attributedText = formattedText

        button.oex_addAction({[weak self] (action) in
            self?.delegate?.openInExternalBrower()
        }, for: UIControl.Event.touchUpInside)
    }
}
