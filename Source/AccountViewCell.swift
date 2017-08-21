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
    public var titleLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(titleLabel)
        titleLabel.snp_makeConstraints { make -> Void in
            make.height.equalTo(40)
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
