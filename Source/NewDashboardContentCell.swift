//
//  NewDashboardContentCell.swift
//  edX
//
//  Created by MuhammadUmer on 23/11/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class NewDashboardContentCell: UITableViewCell {
    static let identifier = "NewDashboardContentCell"
    
    var viewController: UIViewController?
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)        
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewController?.removeFromParent()
    }
}
