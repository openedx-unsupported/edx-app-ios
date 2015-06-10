//
//  FullScreenMessageViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 10/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let CloseButtonHeight = 30
private let SeparatorHeight = 2

class FullScreenMessageViewController: UIViewController {

    let messageTextView = UITextView()
    let closeButton = UIButton()
    let separator = UIView()
    
    init(message : String!, bottomButtonTitle : String!) {
        messageTextView.text = message
        closeButton.setTitle(bottomButtonTitle, forState: .Normal)
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var messageFontStyle : OEXTextStyle {
        return OEXTextStyle(font: OEXTextFont.ThemeSans, size: 14)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(messageTextView)
        view.addSubview(closeButton)
        view.addSubview(separator)
        
        messageTextView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(30)
            make.leadingMargin.equalTo(self.view)
            make.trailingMargin.equalTo(self.view)
            make.bottom.equalTo(separator.snp_top)
        }
        
        closeButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.height.equalTo(CloseButtonHeight)
        }
        
        separator.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(SeparatorHeight)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(closeButton.snp_top)
        }
        
        messageFontStyle.applyToTextView(messageTextView)

        closeButton.setTitleColor(OEXStyles.sharedStyles().neutralBlackT(), forState: .Normal)
        closeButton.oex_addAction({ (sender:AnyObject) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }, forEvents: UIControlEvents.TouchUpInside)
        
        separator.backgroundColor = OEXStyles.sharedStyles().neutralLight()
    }

}
