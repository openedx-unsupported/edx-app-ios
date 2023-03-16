//
//  ResumeCourseHeaderView.swift
//  edX
//
//  Created by MuhammadUmer on 12/03/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

class ResumeCourseHeaderView: UIView {
    
    var tapAction: (() -> ())?
    
    private lazy var button: UIButton = {
        let button = UIButton()
                
        let lockedImage = Icon.ArrowForward.imageWithFontSize(size: 14).image(with: OEXStyles.shared().primaryBaseColor())
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = lockedImage
        
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: -3, width: image.size.width, height: image.size.height)
        }
        
        let attributedImageString = NSAttributedString(attachment: imageAttachment)
        let style = OEXTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().primaryBaseColor())
        
        let attributedStrings = [
            style.attributedString(withText: Strings.Dashboard.resumeCourse),
            NSAttributedString(string: "  "),
            attributedImageString,
        ]
        
        let attributedTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
        
        button.setAttributedTitle(attributedTitle, for: UIControl.State())
        button.backgroundColor = .clear
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.layer.cornerRadius = 0
        button.layer.masksToBounds = true
        button.oex_addAction({ [weak self] _ in
            self?.tapAction?()
        }, for: .touchUpInside)
        return button
    }()
    
    init() {
        super.init(frame: .zero)
        setupViews()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(button)
    }
    
    private func setConstraints() {
        button.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
}
