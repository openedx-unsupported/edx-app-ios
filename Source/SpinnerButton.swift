//
//  SpinnerButton.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 16/09/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit



class SpinnerButton: UIButton {
    private let SpinnerViewTrailingMargin : CGFloat = 10
    private let VerticalContentMargin : CGFloat = 5
    private let SpinnerHorizontalMargin : CGFloat = 10
    private var SpinnerViewWidthWithMargins : CGFloat {
        return spinnerView.intrinsicContentSize.width + 2 * SpinnerHorizontalMargin
    }
    
    private let spinnerView = SpinnerView(size: .Large, color: .White)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSpinnerView()
    }
    
    private func layoutSpinnerView() {
        self.addSubview(spinnerView)
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        
        spinnerView.snp.remakeConstraints { make in
            make.centerY.equalTo(self)
            make.width.equalTo(spinnerView.intrinsicContentSize.width)
            if let label = titleLabel {
                make.leading.equalTo(label.snp.trailing).offset(SpinnerHorizontalMargin).priority(.low)
            }
            make.trailing.equalTo(self.snp.trailing).offset(-SpinnerHorizontalMargin).priority(.high)
        }
        self.setNeedsUpdateConstraints()
        if !showProgress { spinnerView.isHidden = true }
    }
    
    override var intrinsicContentSize: CGSize {
        let width = self.titleLabel?.intrinsicContentSize.width ?? 0 + SpinnerViewTrailingMargin + self.spinnerView.intrinsicContentSize.width
        let height = max(super.intrinsicContentSize.height, spinnerView.intrinsicContentSize.height + 2 * VerticalContentMargin)
        return CGSize(width: width, height: height)
    }
    
    var showProgress : Bool = false {
        didSet {
            if showProgress {
                spinnerView.isHidden = false
                spinnerView.startAnimating()
            }
            else {
                spinnerView.isHidden = true
                spinnerView.stopAnimating()
            }
        }
    }
}
