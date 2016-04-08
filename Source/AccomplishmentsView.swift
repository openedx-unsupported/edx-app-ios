//
//  AccomplishmentsView.swift
//  edX
//
//  Created by Akiva Leffert on 4/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class Accomplishment {
    let image: RemoteImage
    let title: String?
    let detail: String?
    let date: NSDate?
    let shareURL: NSURL

    init(image: RemoteImage, title: String?, detail: String?, date: NSDate?, shareURL: NSURL) {
        self.image = image
        self.title = title
        self.detail = detail
        self.date = date
        self.shareURL = shareURL
    }
}

class AccomplishmentView : UIView {
    private let imageView = UIImageView()
    private let title = UILabel()
    private let detail = UILabel()
    private let date = UILabel()
    private let shareButton = UIButton()
    private let textStack = TZStackView()

    init(accomplishment: Accomplishment, shareAction: () -> Void) {
        super.init(frame: CGRectZero)
        textStack.axis = .Vertical

        // horizontal: imageView - textStack(stretches) - shareButton
        addSubview(imageView)
        addSubview(textStack)
        addSubview(shareButton)
        // vertical stack in the center
        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(detail)
        textStack.addArrangedSubview(date)

        shareButton.setImage(UIImage(named: "share"), forState: .Normal)
        shareButton.tintColor = OEXStyles.sharedStyles().neutralLight()
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        shareButton.oex_addAction({ _ in
            shareAction()
            }, forEvents: .TouchUpInside)

        imageView.snp_makeConstraints {make in
            make.size.equalTo(CGSizeMake(50, 50))
            make.leading.equalTo(self)
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.bottom.lessThanOrEqualTo(self).offset(-StandardVerticalMargin)
        }

        textStack.snp_makeConstraints {make in
            make.leading.equalTo(imageView.snp_trailing).offset(StandardHorizontalMargin)
            make.top.equalTo(self)
            make.bottom.lessThanOrEqualTo(self)
        }

        shareButton.snp_makeConstraints {make in
            make.leading.equalTo(textStack.snp_trailing).offset(StandardHorizontalMargin)
            make.centerY.equalTo(imageView)
            make.trailing.equalTo(self)
        }

        self.title.numberOfLines = 0
        self.detail.numberOfLines = 0

        self.imageView.remoteImage = accomplishment.image

        let formattedDate = accomplishment.date.map { OEXDateFormatting.formatAsDateMonthYearStringWithDate($0) }

        for (field, text, style) in [
            (self.title, accomplishment.title, titleStyle),
            (self.detail, accomplishment.detail, detailStyle),
            (self.date, formattedDate, dateStyle)
            ]
        {
            field.attributedText = style.attributedStringWithText(text)
            field.hidden = text?.isEmpty ?? true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var titleStyle : OEXTextStyle {
        return OEXTextStyle(weight: .SemiBold, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
    }

    private var detailStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBase())
    }

    private var dateStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Light, size: .XSmall, color: OEXStyles.sharedStyles().neutralLight())
    }
}

class AccomplishmentsView : UIView {

    private let stack = TZStackView()

    init(accomplishments : [Accomplishment], shareAction: Accomplishment -> Void) {
        super.init(frame: CGRectZero)
        addSubview(stack)
        stack.axis = .Vertical
        stack.alignment = .Fill
        stack.spacing = StandardVerticalMargin
        stack.snp_makeConstraints {make in
            make.edges.equalTo(self)
        }

        for accomplishment in accomplishments {
            stack.addArrangedSubview(
                AccomplishmentView(accomplishment: accomplishment) { shareAction(accomplishment) })
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}