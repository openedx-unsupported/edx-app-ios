//
//  SubjectCollectionViewCell.swift
//  edX
//
//  Created by Zeeshan Arif on 5/23/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class SubjectCollectionViewCell: UICollectionViewCell {
    static let identifier = "SubjectCollectionViewCellIdentifier"
    
    private(set) var subject: Subject? {
        didSet {
            imageView.image = subject?.image ?? nil
            subjectNameLabel.text = subject?.name ?? ""
        }
    }
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "SubjectCollectionViewCell:image-view"
        return imageView
    }()
    
    lazy var subjectNameLabel: UILabel = {
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
        contentView.addSubview(subjectNameLabel)
        setConstraints()
    }
    
    private func setConstraints() {
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        
        subjectNameLabel.snp.makeConstraints { make in
            make.height.lessThanOrEqualToSuperview().offset(StandardHorizontalMargin)
            make.width.lessThanOrEqualToSuperview().offset(StandardHorizontalMargin)
            make.center.equalToSuperview()
        }
    }
    
    func configure(subject: Subject) {
        self.subject = subject
    }
    
}

