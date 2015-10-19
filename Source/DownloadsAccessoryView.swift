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
        case Done
    }
    
    private let downloadButton = UIButton(type: .System)
    private let downloadSpinner = SpinnerView(size: .Medium, color: .Primary)
    private let iconFontSize : CGFloat = 15
    private let countLabel : UILabel = UILabel()
    
    override init(frame : CGRect) {
        state = .Available
        itemCount = nil
        
        super.init(frame: frame)
        
        downloadButton.tintColor = OEXStyles.sharedStyles().neutralBase()
        downloadButton.contentEdgeInsets = UIEdgeInsetsMake(15, 10, 15, 10)
        
        self.addSubview(downloadButton)
        self.addSubview(downloadSpinner)
        self.addSubview(countLabel)
        
        // This view is atomic from an accessibility point of view
        self.isAccessibilityElement = true
        downloadSpinner.accessibilityTraits = UIAccessibilityTraitNotEnabled;
        countLabel.accessibilityTraits = UIAccessibilityTraitNotEnabled;
        downloadButton.accessibilityTraits = UIAccessibilityTraitNotEnabled;
        
        downloadSpinner.stopAnimating()
        
        downloadSpinner.snp_makeConstraints {make in
            make.center.equalTo(self)
        }
        
        downloadButton.snp_makeConstraints {make in
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
        
        countLabel.snp_makeConstraints {make in
            make.leading.equalTo(self)
            make.centerY.equalTo(self)
            make.trailing.equalTo(downloadButton.imageView!.snp_leading).offset(-6)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func useIcon(icon : Icon?) {
        downloadButton.setImage(icon?.imageWithFontSize(iconFontSize), forState:.Normal)
    }
    
    var downloadAction : (() -> Void)? = nil {
        didSet {
            downloadButton.oex_removeAllActions()
            downloadButton.oex_addAction({ _ in downloadAction?() }, forEvents: .TouchUpInside)
        }
    }
    
    var itemCount : Int? {
        didSet {
            let count = itemCount ?? 0
            let text = (count > 0 ? "\(count)" : "")
            let styledText = CourseOutlineItemView.detailFontStyle.attributedStringWithText(text)
            countLabel.attributedText = styledText
        }
    }
    
    var state : State {
        didSet {
            switch state {
            case .Available:
                useIcon(.ContentCanDownload)
                downloadSpinner.hidden = true
                downloadButton.userInteractionEnabled = true
                downloadButton.hidden = false
                self.userInteractionEnabled = true
                countLabel.hidden = false
                
                if let count = itemCount {
                    let message = Strings.downloadManyVideos(videoCount: Float(count))
                    self.accessibilityLabel = message
                }
                else {
                    self.accessibilityLabel = Strings.download
                }
                self.accessibilityTraits = UIAccessibilityTraitButton
            case .Downloading:
                downloadSpinner.startAnimating()
                downloadSpinner.hidden = false
                downloadButton.userInteractionEnabled = true
                self.userInteractionEnabled = true
                downloadButton.hidden = true
                countLabel.hidden = true
                
                self.accessibilityLabel = Strings.downloading
                self.accessibilityTraits = UIAccessibilityTraitButton
            case .Done:
                useIcon(.ContentDidDownload)
                downloadSpinner.hidden = true
                self.userInteractionEnabled = false
                downloadButton.hidden = false
                countLabel.hidden = false
                
                if let count = itemCount {
                    let message = Strings.downloadManyVideos(videoCount: Float(count))
                    self.accessibilityLabel = message
                }
                else {
                    self.accessibilityLabel = Strings.downloaded
                }
                self.accessibilityTraits = UIAccessibilityTraitStaticText
            }
        }
    }
}
