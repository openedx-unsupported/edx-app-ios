//
//  SubjectCollectionViewCell.swift
//  edX
//
//  Created by Zeeshan Arif on 5/23/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class SubjectCollectionViewCell: UICollectionViewCell {
    static let identifier = "SubjectCollectionViewCell"
    static var defaultHeight: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 90 : 70
    }
    static var defaultWidth: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 200 : 150
    }
    static let defaultMargin: CGFloat = 10
    
    private(set) var subject: Subject? {
        didSet {
            let style = OEXMutableTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralWhite())
            style.alignment = .center
            imageView.image = subject?.image ?? #imageLiteral(resourceName: "logo.png")
            nameLabel.attributedText = style.attributedString(withText: subject?.name ?? "")
        }
    }
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 5
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.accessibilityIdentifier = "SubjectCollectionViewCell:image-view"
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "SubjectCollectionViewCell:subject-name-label"
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        setConstraints()
    }
    
    private func setConstraints() {
        imageView.snp.makeConstraints { make in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(SubjectCollectionViewCell.defaultHeight)
            make.center.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { make in
            make.height.lessThanOrEqualToSuperview().offset(StandardVerticalMargin)
            make.width.equalTo(imageView).inset(StandardHorizontalMargin)
            make.center.equalTo(imageView)
        }
    }
    
    func configure(subject: Subject) {
        self.subject = subject
        nameLabel.accessibilityHint = Strings.Accessibility.browserBySubjectHint(subjectName: subject.name)
    }
    
}

