//
//  VideoTranscriptTableViewCell.swift
//  edX
//
//  Created by Danial Zahid on 1/13/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class VideoTranscriptTableViewCell: UITableViewCell {
    
    static let cellIdentifier = "VideoTranscriptCell"
    
    let titleLabel = UILabel(frame: CGRect.zero)
    
    private var standardTitleStyle : OEXTextStyle {
        let style = OEXTextStyle(weight: OEXTextWeight.semiBold, size: .base, color: OEXStyles.shared().primaryBaseColor())
        titleLabel.lineBreakMode = .byWordWrapping
        return style
    }
    
    private var highlightedTitleStyle : OEXTextStyle {
        let style = OEXTextStyle(weight: OEXTextWeight.semiBold, size: .base, color: OEXStyles.shared().neutralXDark())
        titleLabel.lineBreakMode = .byWordWrapping
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.white
        titleLabel.numberOfLines = 0
        titleLabel.preferredMaxLayoutWidth = bounds.width
        self.addSubview(titleLabel)
        titleLabel.snp_remakeConstraints { make in
            make.left.equalTo(self.snp_left).offset(20.0)
            make.right.equalTo(self.snp_right).offset(-20.0)
            make.top.equalTo(self.snp_top).offset(10.0)
            make.bottom.equalTo(self.snp_bottom).offset(-10.0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setTranscriptText(text: String? , highlighted: Bool) {
        if !highlighted {
            titleLabel.attributedText = standardTitleStyle.attributedString(withText: text)
        }
        else{
            titleLabel.attributedText = highlightedTitleStyle.attributedString(withText: text)
        }
    }
}
