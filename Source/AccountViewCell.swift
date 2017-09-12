//
//  AccountViewCell.swift
//  edX
//
//  Created by Salman on 15/08/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class AccountViewCell: UITableViewCell {

    static let identifier = "accountViewCellIdentifier"
    private var titleLabel = UILabel()
    private let titleStyle = OEXTextStyle(weight: .normal, size: .large, color : OEXStyles.shared().neutralBlack())
    public var title : String? {
        didSet {
            titleLabel.attributedText = titleStyle.attributedString(withText: title)
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        contentView.addSubview(titleLabel)
        titleLabel.snp_makeConstraints { make -> Void in
            make.top.equalTo(contentView).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
