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
    private let viewAllSubjectsStyle = OEXTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralWhite())
    
    lazy var viewAllSubjectsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.accessibilityIdentifier = "ViewAllSubjectsCollectionViewCell:view-all-subjects-label"
        label.attributedText = self.viewAllSubjectsStyle.attributedString(withText: Strings.viewAllSubjects)
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        contentView.backgroundColor = OEXStyles.shared().primaryBaseColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        contentView.addSubview(viewAllSubjectsLabel)
        setConstraints()
    }
    
    private func setConstraints() {
        viewAllSubjectsLabel.snp.makeConstraints { make in
            make.height.lessThanOrEqualToSuperview().offset(StandardHorizontalMargin)
            make.width.lessThanOrEqualTo(contentView).inset(StandardVerticalMargin)
            make.center.equalToSuperview()
        }
    }
}
