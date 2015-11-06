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

    override var enabled: Bool {
        didSet {
            titleLabel.attributedText = enabled ? enabledAttributedString : disabledAttributedString
            tintColor = enabled ? OEXStyles.sharedStyles().primaryBaseColor() : OEXStyles.sharedStyles().disabledButtonColor()
        }
    }

    override var highlighted: Bool {
        didSet {
            alpha = highlighted ? 0.5 : 1
        }
    }

    init() {
        super.init(frame: CGRectZero)

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

    override func intrinsicContentSize() -> CGSize {
        let imSize = imageView.intrinsicContentSize()
        let titleSize = titleLabel.intrinsicContentSize()
        let height = max(imSize.height, titleSize.height)
        let width = imSize.width + titleSize.width + spacing
        return CGSize(width: width, height: height)
    }


    func setIconAndTitle(icon: Icon, title: String) {
        let titleStyle = OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().primaryBaseColor())
        let disabledTitleStyle = OEXMutableTextStyle(textStyle: titleStyle)
        disabledTitleStyle.color = OEXStyles.sharedStyles().disabledButtonColor()

        let imageSize = OEXTextStyle.pointSizeForTextSize(titleStyle.size)
        let image = icon.imageWithFontSize(imageSize)
        imageView.image = image

        enabledAttributedString = titleStyle.attributedStringWithText(title)
        disabledAttributedString = disabledTitleStyle.attributedStringWithText(title)
        titleLabel.attributedText = enabled ? enabledAttributedString : disabledAttributedString
    }
}
