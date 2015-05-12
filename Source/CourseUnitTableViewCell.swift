//
//  CourseUnitTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 12/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnitTableViewCell: UITableViewCell {

    static let identifier = "CourseUnitTableViewCellIdentifier"
    
    var label : UILabel = UILabel()
    var leftImage : UIImageView  = UIImageView()
    
    var block : CourseBlock? = nil {
        didSet {
            label.text = block?.name ?? ""
        }
    }
    
    func setStyle(){
        self.label.font = UIFont(name: "OpenSans-Regular", size: 14)
    }
    
    func setConstraints(){
        label.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self)
            
        }
        label.sizeToFit()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(label)
        setStyle()
        setConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
}
