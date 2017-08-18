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
    private let titleLabel = UILabel()
    private let separatorImage = UIImageView(image: UIImage(named: "separator.png"))
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        titleLabel.textColor = OEXStyles.shared().neutralBlackT()
        contentView.addSubview(titleLabel)
        titleLabel.snp_makeConstraints { make -> Void in
            make.height.equalTo(40)
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView).offset(20)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureView(withTitle title: String){
        titleLabel.text = title
    }
}
