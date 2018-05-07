//
//  DownloadsAccessoryView.swift
//  edX
//
//  Created by Akiva Leffert on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit


class DownloadsAccessoryView : UIView {
    
    enum State {
        case Available
        case Downloading
        case Deleting
        case Done
    }
    
    private let downloadButton = UIButton(type: .system)
    private let downloadSpinner = SpinnerView(size: .Medium, color: .Primary)
    private let iconFontSize : CGFloat = 15
    private let countLabel : UILabel = UILabel()
    
    override init(frame : CGRect) {
        state = .Available
        itemCount = nil
        
        super.init(frame: frame)
        
        downloadButton.tintColor = OEXStyles.shared().neutralBase()
        downloadButton.contentEdgeInsets = UIEdgeInsetsMake(15, 10, 15, 10)
        downloadButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        downloadSpinner.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        
        self.addSubview(downloadButton)
        self.addSubview(downloadSpinner)
        self.addSubview(countLabel)
        
        // This view is atomic from an accessibility point of view
        self.isAccessibilityElement = true
        downloadSpinner.accessibilityTraits = UIAccessibilityTraitNotEnabled;
        countLabel.accessibilityTraits = UIAccessibilityTraitNotEnabled;
        downloadButton.accessibilityTraits = UIAccessibilityTraitNotEnabled;
        
        downloadSpinner.stopAnimating()
        
        downloadSpinner.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
        
        downloadButton.snp.makeConstraints { make in
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
        
        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.centerY.equalTo(self)
            make.trailing.equalTo(downloadButton.imageView!.snp.leading).offset(-6)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func useIcon(icon : Icon?) {
        downloadButton.setImage(icon?.imageWithFontSize(size: iconFontSize), for:.normal)
    }
    
    var downloadAction : (() -> Void)? = nil {
        didSet {
            downloadButton.oex_removeAllActions()
            downloadButton.oex_addAction({ _ in self.downloadAction?() }, for: .touchUpInside)
        }
    }
    
    var itemCount : Int? {
        didSet {
            let count = itemCount ?? 0
            let text = (count > 0 ? "\(count)" : "")
            let styledText = CourseOutlineItemView.detailFontStyle.attributedString(withText: text)
            countLabel.attributedText = styledText
        }
    }
    
    var state : State {
        didSet {
            switch state {
            case .Available:
                useIcon(icon: .ContentCanDownload)
                downloadSpinner.isHidden = true
                downloadButton.isUserInteractionEnabled = true
                downloadButton.isHidden = false
                isUserInteractionEnabled = true
                countLabel.isHidden = false
                
                if let count = itemCount {
                    let message = Strings.downloadManyVideos(videoCount: count)
                    accessibilityLabel = message
                }
                else {
                    accessibilityLabel = Strings.download
                }
                accessibilityTraits = UIAccessibilityTraitButton
            case .Downloading:
                downloadSpinner.startAnimating()
                downloadSpinner.isHidden = false
                downloadButton.isUserInteractionEnabled = true
                isUserInteractionEnabled = true
                downloadButton.isHidden = true
                countLabel.isHidden = true
                
                accessibilityLabel = Strings.downloading
                accessibilityTraits = UIAccessibilityTraitButton
            case .Deleting:
                downloadSpinner.startAnimating()
                downloadSpinner.isHidden = false
                downloadButton.isUserInteractionEnabled = false
                isUserInteractionEnabled = false
                downloadButton.isHidden = true
                countLabel.isHidden = true
                
                accessibilityLabel = Strings.downloading
                accessibilityTraits = UIAccessibilityTraitButton
            case .Done:
                useIcon(icon: .ContentDidDownload)
                downloadSpinner.isHidden = true
                isUserInteractionEnabled = false
                downloadButton.isHidden = false
                countLabel.isHidden = false
                
                if let count = itemCount {
                    let message = Strings.downloadManyVideos(videoCount: count)
                    accessibilityLabel = message
                }
                else {
                    accessibilityLabel = Strings.downloaded
                }
                accessibilityTraits = UIAccessibilityTraitStaticText
            }
        }
    }
}
