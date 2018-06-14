//
//  ViewAllSubjectsCollectionViewCell.swift
//  edX
//
//  Created by Zeeshan Arif on 5/25/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class ViewAllSubjectsCollectionViewCell: UICollectionViewCell {
    static let identifier = "ViewAllSubjectsCollectionViewCell"
    
    private lazy var subjectsLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "ViewAllSubjectsCollectionViewCell:view-all-subjects-label"
        label.accessibilityHint = Strings.Accessibility.viewAllSubjectsHint
        let style = OEXMutableTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralWhite())
        style.alignment = .center
        label.attributedText = style.attributedString(withText: Strings.Discovery.viewAllSubjects)
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = OEXStyles.shared().primaryBaseColor()
        contentView.layer.cornerRadius = 5.0
        addSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        contentView.addSubview(subjectsLabel)
        setConstraints()
    }
    
    private func setConstraints() {
        subjectsLabel.snp.makeConstraints { make in
            make.height.lessThanOrEqualToSuperview().offset(StandardVerticalMargin)
            make.width.lessThanOrEqualTo(contentView).inset(StandardHorizontalMargin)
            make.center.equalToSuperview()
        }
    }
}
