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
        
        titleLabel.textColor = UIColor.black
        titleLabel.frame = CGRect(x: 20, y: 0, width: 200, height: contentView.frame.size.height)
        contentView.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureView(withTitle title: String){
        titleLabel.text = title
    }
}
