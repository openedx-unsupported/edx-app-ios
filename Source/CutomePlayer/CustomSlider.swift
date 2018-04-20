//
//  CustomSlider.swift
//  edX
//
//  Created by Salman on 25/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class CustomSlider: UISlider {
    
   private var progressView = UIProgressView()

    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
            loadSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var secondaryTrackColor : UIColor {
        set {
            progressView.progressTintColor = newValue
        }
        get {
            return progressView.progressTintColor ?? UIColor.clear
        }
    }
    
    var secondaryProgress: Float {
        set {
            progressView.progress = newValue
        }
        get {
            return progressView.progress
        }
    }
    
   private func loadSubViews() {
        progressView.progress = 0.7
        backgroundColor = UIColor.clear
        maximumTrackTintColor = UIColor.clear
        addSubview(progressView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressView.frame = CGRect(x: 2, y: frame.size.height / 2 - 1, width: frame.size.width - 2, height: frame.size.height);
    }

}
