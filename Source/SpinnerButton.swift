//
//  SpinnerButton.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 16/09/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class SpinnerButton: UIButton {
    let SPINNER_VIEW_TRAILING_MARGIN : CGFloat = 10
    let VERTICAL_CONTENT_MARGINS : CGFloat = 20
    
    let spinnerView = SpinnerView(size: .Large, color: .White)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSpinnerView()
    }
    
    func layoutSpinnerView() {
        self.addSubview(spinnerView)
        spinnerView.snp_updateConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.width.equalTo(spinnerView.intrinsicContentSize().width)
            make.trailing.equalTo(self.snp_trailing).offset(-10).priorityHigh()
        }
        self.setNeedsUpdateConstraints()
        if !showProgress { spinnerView.hidden = true }
    }
    
    override func intrinsicContentSize() -> CGSize {
        let width = self.titleLabel?.intrinsicContentSize().width ?? 0 + SPINNER_VIEW_TRAILING_MARGIN + self.spinnerView.intrinsicContentSize().width
        let height = (self.titleLabel?.intrinsicContentSize().height ?? spinnerView.intrinsicContentSize().height) + VERTICAL_CONTENT_MARGINS
        
        return CGSizeMake(width, height)
    }
    
    var showProgress : Bool = false {
        didSet {
            if showProgress {
                spinnerView.hidden = false
                spinnerView.startAnimating()
            }
            else {
                spinnerView.hidden = true
                spinnerView.stopAnimating()
            }
            self.setNeedsLayout()
        }
    }
    
}
