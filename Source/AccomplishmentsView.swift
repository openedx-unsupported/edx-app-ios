//
//  AccomplishmentsView.swift
//  edX
//
//  Created by Akiva Leffert on 4/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

struct Accomplishment {
    let image: RemoteImage
    let title: String?
    let detail: String?
    let date: NSDate?
    let shareURL: NSURL
}

class AccomplishmentView : UIView {
    private let imageView = UIImageView()
    private let title = UILabel()
    private let detail = UILabel()
    private let date = UILabel()
    private let shareButton = UIButton()
    private let textStack = TZStackView()

    init(accomplishment: Accomplishment, shareAction: (() -> Void)?) {
        super.init(frame: CGRectZero)
        textStack.axis = .Vertical

        // horizontal: imageView - textStack(stretches) - shareButton
        addSubview(imageView)
        addSubview(textStack)
        let sharing = shareAction != nil

        if(sharing) {
            addSubview(shareButton)
        }
        // vertical stack in the center
        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(detail)
        textStack.addArrangedSubview(date)

        shareButton.setImage(UIImage(named: "share"), forState: .Normal)
        shareButton.tintColor = OEXStyles.sharedStyles().neutralLight()
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        shareButton.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        shareButton.oex_addAction({ _ in
            shareAction?()
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

        if sharing {
            shareButton.snp_makeConstraints {make in
                make.leading.equalTo(textStack.snp_trailing).offset(StandardHorizontalMargin)
                make.centerY.equalTo(imageView)
                make.trailing.equalTo(self)
            }
        }
        else {
            textStack.snp_makeConstraints {make in
                make.trailing.equalTo(self)
            }
        }

        title.numberOfLines = 0
        detail.numberOfLines = 0

        imageView.remoteImage = accomplishment.image

        let formattedDate = accomplishment.date.map { OEXDateFormatting.formatAsMonthDayYearString($0) }

        for (field, text, style) in [
            (title, accomplishment.title, titleStyle),
            (detail, accomplishment.detail, detailStyle),
            (date, formattedDate, dateStyle)
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
    private let shareAction: (Accomplishment -> Void)?

    private var accomplishments: [Accomplishment] = []
    private let paginationController: PaginationController<Accomplishment>

    // If shareAction is nil then don't show sharing buttons
    init(paginator: AnyPaginator<Accomplishment>, containingScrollView scrollView: UIScrollView, shareAction: (Accomplishment -> Void)?) {
        self.shareAction = shareAction
        paginationController = PaginationController(paginator: paginator, stackView: stack, containingScrollView: scrollView)

        super.init(frame: CGRectZero)

        addSubview(stack)
        stack.axis = .Vertical
        stack.alignment = .Fill
        stack.spacing = StandardVerticalMargin
        stack.snp_makeConstraints {make in
            make.edges.equalTo(self)
        }
        paginator.stream.listen(self, success: {[weak self] accomplishments in
            let newAccomplishments = accomplishments.suffixFrom(self?.accomplishments.count ?? 0)
            self?.addAccomplishments(newAccomplishments)
            }, failure: {_ in
                // We should only get here if we already have accomplishments and the paginator will try to
                // load again if it fails, so just do nothing
        })
    }

    func addAccomplishments<A: SequenceType where A.Generator.Element == Accomplishment>(newAccomplishments: A) {
        let action = shareAction
        for accomplishment in newAccomplishments {
            stack.addArrangedSubview(
                AccomplishmentView(accomplishment: accomplishment, shareAction: action.map {f in { f(accomplishment) }})
            )
        }
        accomplishments.appendContentsOf(newAccomplishments)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
