//
//  DetailToolbarButton.swift
//  edX
//
//  Created by Akiva Leffert on 6/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

/// A simple two line button with an action and detail text text.
/// Views of this class are meant to be embedded in a UIBarButtonItem in a UIToolbar
class DetailToolbarButton: UIView {

    enum Direction {
        case Next
        case Prev
    }
    
    let direction : Direction
    
    let button = UIButton.buttonWithType(.System) as! UIButton
    
    init(direction : Direction, titleText : String, destinationText : String?, action : () -> Void) {
        self.direction = direction
        // TODO: Switch to size classes when giving htis this a maximum size when we add tablet support
        super.init(frame: CGRectMake(0, 0, 140, 44))
        
        addSubview(button)
        
        let styledTitle = titleStyle.attributedStringWithText(titleText)

        var title: NSAttributedString
        if let destination = destinationText {
            let styledDestination = destinationStyle.attributedStringWithText(destination)
        
            title = NSAttributedString(string: "{top}\n{bottom}", attributes : titleStyle.attributes).oex_formatWithParameters(["top" : styledTitle, "bottom" : styledDestination])
        } else {
            title = NSAttributedString(string: "{top}", attributes : titleStyle.attributes).oex_formatWithParameters(["top" : styledTitle])
        }
        
        button.titleLabel?.numberOfLines = 2
        button.setAttributedTitle(title, forState: .Normal)
        
        let disabledTitle = NSMutableAttributedString(attributedString: title)
        disabledTitle.setAttributes([NSForegroundColorAttributeName: OEXStyles.sharedStyles().disabledButtonColor()], range: NSMakeRange(0, title.length))
        button.setAttributedTitle(disabledTitle, forState: .Disabled)
        
        button.contentHorizontalAlignment = buttonAlignment
        button.oex_addAction({_ in action() }, forEvents: .TouchUpInside)
        
        button.snp_makeConstraints {make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var buttonAlignment : UIControlContentHorizontalAlignment {
        // TODO: Deal with RTL once we add iOS 9 support and swap the toolbar buttons depending on layout
        // direction
        switch direction {
        case .Next: return .Right
        case .Prev: return .Left
        }
    }
    
    var textAlignment : NSTextAlignment {
        // TODO: Deal with RTL once we add iOS 9 support and swap the toolbar buttons depending on layout
        // direction
        switch direction {
        case .Next: return .Right
        case .Prev: return .Left
        }
    }
    
    private var titleStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: .SemiBold, size: .Small, color: OEXStyles.sharedStyles().primaryBaseColor())
        style.alignment = self.textAlignment
        return style
    }
    
    private var destinationStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBase())
        style.alignment = self.textAlignment
        return style
    }
}
