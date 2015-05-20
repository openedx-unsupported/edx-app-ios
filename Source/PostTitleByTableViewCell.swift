//
//  PostTitleByTableViewCell.swift
//  edX
//
//  Created by Tang, Jeff on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


// Uncomment for PostViewControllerUsingStoryboard.swift
//class PostTitleByTableViewCell: UITableViewCell {
//
//    @IBOutlet weak var ivType: UIImageView!
//    @IBOutlet weak var ivBy: UIImageView!
//    @IBOutlet weak var lblTitle: UILabel!
//    @IBOutlet weak var lblBy: UILabel!
//    @IBOutlet weak var btnCount: UIButton!
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
//
//}


// Use for PostViewControllerUsingCode.swift
class PostTitleByTableViewCell: UITableViewCell {
    
    var ivType: UIImageView! = UIImageView()
    var ivBy: UIImageView! = UIImageView()
    var lblTitle: UILabel! = UILabel()
    var lblBy: UILabel! = UILabel()
    var btnCount: UIButton! = UIButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(ivType)
        ivType.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.contentView).offset(7)
            make.centerY.equalTo(self.contentView).offset(0)
            make.width.equalTo(25)
            make.height.equalTo(25)
        }

        lblTitle.font = UIFont(name: "HelveticaNeue", size: CGFloat(14))
        contentView.addSubview(lblTitle)
        lblTitle.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(ivType.snp_right).offset(8)
            make.top.equalTo(self.contentView).offset(10)
            make.height.equalTo(20)
            make.width.equalTo(200)
        }
        
        contentView.addSubview(ivBy)
        ivBy.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(lblTitle)
            make.top.equalTo(lblTitle.snp_bottom).offset(12)
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        
        lblBy.font = UIFont(name: "HelveticaNeue", size: CGFloat(12))
        lblBy.textColor = UIColor(red: 17 / 255, green: 137 / 255, blue: 227 / 255, alpha: 1.0)
        contentView.addSubview(lblBy)
        lblBy.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(ivBy.snp_right).offset(5)
            make.top.equalTo(lblTitle.snp_bottom).offset(11)
            make.width.equalTo(200)
            make.height.equalTo(20)
        }
        
        contentView.addSubview(btnCount)
        btnCount.setTitleColor(UIColor(red: 17 / 255, green: 137 / 255, blue: 227 / 255, alpha: 1.0), forState: .Normal)
        btnCount.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.contentView).offset(-9)
            make.centerY.equalTo(self.contentView).offset(0)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
    }
    

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
