//
//  DiscussionTopicsCell.swift
//  edX

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

class DiscussionTopicsCell: UITableViewCell {

    static let identifier = "DiscussionTopicsCellIdentifier"
    
    var container = UIView()
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    var separatorLine = UIView()
    
    var titleTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 12.0)
        style.color = OEXStyles.sharedStyles()?.neutralBlack()
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViews() {
        self.separatorLine.backgroundColor = OEXStyles.sharedStyles()?.neutralXXLight()
        
        titleTextStyle.applyToLabel(self.titleLabel)
        
        self.container.addSubview(iconImageView)
        self.container.addSubview(titleLabel)
        
        self.contentView.addSubview(container)
        self.contentView.addSubview(separatorLine)
        
        self.separatorLine.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.contentView)
            make.right.equalTo(self.contentView)
            make.top.equalTo(self.contentView)
            make.height.equalTo(1)
        }
        
        self.container.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.contentView)
            make.right.equalTo(self.contentView)
            make.top.equalTo(self.separatorLine.snp_bottom)
            make.bottom.equalTo(self.contentView)
        }
        
        self.iconImageView.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.container).offset(15)
            make.centerY.equalTo(self.container)
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.iconImageView.snp_right).offset(10)
            make.right.equalTo(self.contentView).offset(-10)
            make.centerY.equalTo(self.container)
            make.height.equalTo(20)
        }
    }

}
