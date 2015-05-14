//
//  CourseDashboardCell.swift
//  edX
//

/**
Copyright (c) 2015 Qualcomm Education, Inc.
All rights reserved.


Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

* Neither the name of Qualcomm Education, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

import UIKit

class CourseDashboardCell: UITableViewCell {

    static let identifier = "CourseDashboardCellIdentifier"
    
    static let titleTextColor = UIColor.blackColor()
    static let titleTextFont = UIFont(name: "HelveticaNeue", size: CGFloat(14))
    static let detailTextColor = UIColor(red: 100/255.0, green: 100/255.0, blue: 100/255.0, alpha: 1.0)
    static let detailTextFont = UIFont(name: "HelveticaNeue", size: CGFloat(11))
    
    var container = UIView()
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    var detailLabel = UILabel()
    var indicatorImageView = UIImageView()
    var bottomLine = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViews() {
        self.bottomLine.backgroundColor = UIColor(red: 224.0/255.0, green: 224.0/255.0, blue: 224.0/255.0, alpha: 1.0)
        
        self.titleLabel.textColor = CourseDashboardCell.titleTextColor
        self.titleLabel.font = CourseDashboardCell.titleTextFont
        self.detailLabel.textColor = CourseDashboardCell.detailTextColor
        self.detailLabel.font = CourseDashboardCell.detailTextFont
        
        self.container.addSubview(iconImageView)
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        self.container.addSubview(indicatorImageView)
        
        self.contentView.addSubview(container)
        self.contentView.addSubview(bottomLine)
        
        self.container.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.contentView).offset(0)
            make.right.equalTo(self.contentView).offset(0)
            make.top.equalTo(self.contentView).offset(0)
            make.bottom.equalTo(self.contentView).offset(-1)
        }
        self.bottomLine.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.contentView).offset(0)
            make.right.equalTo(self.contentView).offset(0)
            make.bottom.equalTo(self.contentView).offset(0)
            make.height.equalTo(1)
        }
        self.iconImageView.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.container).offset(15)
            make.centerY.equalTo(self.container).offset(0)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        self.indicatorImageView.snp_makeConstraints { (make) -> Void in
            make.right.equalTo(self.container).offset(-15)
            make.centerY.equalTo(self.container).offset(0)
            make.width.equalTo(10)
            make.height.equalTo(20)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.iconImageView.snp_right).offset(10)
            make.right.equalTo(self.indicatorImageView.snp_left).offset(0)
            make.top.equalTo(self.container).offset(20)
            make.height.equalTo(20)
        }
        self.detailLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.titleLabel).offset(0)
            make.right.equalTo(self.titleLabel).offset(0)
            make.top.equalTo(self.titleLabel.snp_bottom).offset(0)
            make.height.equalTo(20)
        }
    }

}
