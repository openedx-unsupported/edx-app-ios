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
        case Gated
    }
    
    private let downloadButton = UIButton(type: .system)
    private let downloadSpinner = SpinnerView(size: .Medium, color: .Primary)
    private let iconFontSize: CGFloat = 17
    private let countLabel: UILabel = UILabel()
    private let downloadButtonSize = 32
    
    override init(frame: CGRect) {
        state = .Available
        itemCount = nil
        
        super.init(frame: frame)
        
        downloadButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        downloadSpinner.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        addSubview(downloadButton)
        addSubview(downloadSpinner)
        addSubview(countLabel)
        
        // This view is atomic from an accessibility point of view
        isAccessibilityElement = true
        
        downloadSpinner.accessibilityTraits = UIAccessibilityTraits.notEnabled;
        countLabel.accessibilityTraits = UIAccessibilityTraits.notEnabled;
        downloadButton.accessibilityTraits = UIAccessibilityTraits.notEnabled;
        
        downloadSpinner.stopAnimating()
        
        downloadSpinner.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
        
        downloadButton.snp.makeConstraints { make in
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(downloadButtonSize)
            make.width.equalTo(downloadButtonSize)
        }
        
        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(downloadButton.snp.trailing).offset(StandardHorizontalMargin / 3)
            make.centerY.equalTo(self)
        }

        setAccessibilityIdentifiers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        state == .Gated ? removeCircleFromDownloadButton() : addCircleToDownloadButton()
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "DownloadsAccessoryView:view"
        downloadButton.accessibilityIdentifier = "DownloadsAccessoryView:download-button"
        countLabel.accessibilityIdentifier = "DownloadsAccessoryView:count-label"
        downloadSpinner.accessibilityIdentifier = "DownloadsAccessoryView:download-spinner"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addCircleToDownloadButton() {
        downloadButton.backgroundColor = .clear
        downloadButton.layer.borderWidth = 1
        downloadButton.layer.borderColor = OEXStyles.shared().neutralLight().cgColor
        downloadButton.layer.cornerRadius = downloadButton.frame.size.width / 2
        downloadButton.layer.masksToBounds = true
    }
    
    private func removeCircleFromDownloadButton() {
        downloadButton.backgroundColor = .clear
        downloadButton.layer.borderWidth = 0
        downloadButton.layer.borderColor = UIColor.clear.cgColor
        downloadButton.layer.cornerRadius = downloadButton.frame.size.width / 2
        downloadButton.layer.masksToBounds = true
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
                accessibilityTraits = .button
            case .Downloading:
                downloadSpinner.startAnimating()
                downloadSpinner.isHidden = false
                downloadButton.isUserInteractionEnabled = true
                isUserInteractionEnabled = true
                downloadButton.isHidden = true
                countLabel.isHidden = true
                
                accessibilityLabel = Strings.downloading
                accessibilityTraits = .button
            case .Deleting:
                downloadSpinner.startAnimating()
                downloadSpinner.isHidden = false
                downloadButton.isUserInteractionEnabled = false
                isUserInteractionEnabled = false
                downloadButton.isHidden = true
                countLabel.isHidden = true
                
                accessibilityLabel = Strings.downloading
                accessibilityTraits = .button
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
                accessibilityTraits = .staticText
            case .Gated:
                useIcon(icon: .Closed)
                downloadSpinner.isHidden = true
                isUserInteractionEnabled = false
                downloadButton.isHidden = false
                countLabel.isHidden = true
                downloadButton.tintColor = OEXStyles.shared().primaryDarkColor()
                
                accessibilityTraits = .staticText
                accessibilityLabel = Strings.courseContentGated
            }
        }
    }
}
