//
//  FullScreenMessageViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 10/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let CloseButtonHeight = 30

public class FullScreenMessageViewController: UIViewController {
    private let messageTextView = UITextView()
    private let closeButton = UIButton(type: .System)
    private let separator = UIView()
    
    public init(message : String, bottomButtonTitle : String?) {
        super.init(nibName: nil, bundle: nil)
        messageTextView.attributedText = messageFontStyle.attributedStringWithText(message)
        messageTextView.editable = false
        messageTextView.selectable = false
        messageTextView.contentInset = UIEdgeInsetsMake(30, 0, 0, 0)
        
        closeButton.setTitle(bottomButtonTitle, forState: .Normal)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var messageFontStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralBlack())
        style.lineBreakMode = .ByWordWrapping
        return style
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(messageTextView)
        view.addSubview(closeButton)
        view.addSubview(separator)
        
        messageTextView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(separator.snp_top)
        }
        
        closeButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.height.equalTo(CloseButtonHeight)
        }
        
        separator.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(closeButton.snp_top)
        }

        closeButton.setTitleColor(OEXStyles.sharedStyles().neutralBlackT(), forState: .Normal)
        closeButton.oex_addAction({ (sender:AnyObject) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }, forEvents: UIControlEvents.TouchUpInside)
        
        separator.backgroundColor = OEXStyles.sharedStyles().neutralLight()
    }
    
    public override func prefersStatusBarHidden() -> Bool {
        return true
    }

}
