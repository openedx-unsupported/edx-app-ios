//
//  IconButton.swift
//  edX
//
//  Created by Michael Katz on 11/6/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class IconButton : UIControl {
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let spacing: CGFloat = 10

    var enabledAttributedString: NSAttributedString?
    var disabledAttributedString: NSAttributedString?

    override var isEnabled: Bool {
        didSet {
            titleLabel.attributedText = isEnabled ? enabledAttributedString : disabledAttributedString
            tintColor = isEnabled ? OEXStyles.shared().primaryBaseColor() : OEXStyles.shared().disabledButtonColor()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.5 : 1
        }
    }

    init() {
        super.init(frame: CGRect.zero)

        addSubview(imageView)
        addSubview(titleLabel)

        imageView.snp_makeConstraints { (make) -> Void in
            make.baseline.equalTo(titleLabel.snp_baseline).offset(2)
        }
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.leading.equalTo(imageView.snp_trailing).offset(spacing)
            make.trailing.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let imSize = imageView.intrinsicContentSize
        let titleSize = titleLabel.intrinsicContentSize
        let height = max(imSize.height, titleSize.height)
        let width = imSize.width + titleSize.width + spacing
        return CGSize(width: width, height: height)
    }


    func setIconAndTitle(icon: Icon, title: String) {
        let titleStyle = OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().primaryBaseColor())
        let disabledTitleStyle = OEXMutableTextStyle(textStyle: titleStyle)
        disabledTitleStyle.color = OEXStyles.shared().disabledButtonColor()

        let imageSize = OEXTextStyle.pointSize(for: titleStyle.size)
        let image = icon.imageWithFontSize(size: imageSize)
        imageView.image = image

        enabledAttributedString = titleStyle.attributedString(withText: title)
        disabledAttributedString = disabledTitleStyle.attributedString(withText: title)
        titleLabel.attributedText = isEnabled ? enabledAttributedString : disabledAttributedString
    }
}
