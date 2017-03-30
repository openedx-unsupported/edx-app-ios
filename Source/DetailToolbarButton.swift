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
    
    let button = UIButton(type: .system)
    
    init(direction : Direction, titleText : String, destinationText : String?, action : @escaping () -> Void) {
        self.direction = direction
        // TODO: Switch to size classes when giving htis this a maximum size when we add tablet support
        super.init(frame: CGRect(x: 0, y: 0, width: 140, height: 44))
        
        addSubview(button)
        
        let styledTitle = titleStyle.attributedString(withText: titleText)

        var title: NSAttributedString
        if let destination = destinationText {
            let styledDestination = destinationStyle.attributedString(withText: destination)
        
            title = NSAttributedString(string: "{top}\n{bottom}", attributes : titleStyle.attributes).oex_format(withParameters: ["top" : styledTitle, "bottom" : styledDestination])
        } else {
            title = NSAttributedString(string: "{top}", attributes : titleStyle.attributes).oex_format(withParameters: ["top" : styledTitle])
        }
        
        button.titleLabel?.numberOfLines = 2
        button.setAttributedTitle(title, for: .normal)
        
        let disabledTitle = NSMutableAttributedString(attributedString: title)
        disabledTitle.setAttributes([NSForegroundColorAttributeName: OEXStyles.shared().disabledButtonColor()], range: NSMakeRange(0, title.length))
        button.setAttributedTitle(disabledTitle, for: .disabled)
        
        button.contentHorizontalAlignment = buttonAlignment
        button.oex_addAction({_ in action() }, for: .touchUpInside)
        
        button.snp_makeConstraints {make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var buttonAlignment : UIControlContentHorizontalAlignment {
        // TODO: Deal with RTL once we add iOS 9 support and swap the toolbar buttons depending on layout
        // direction
        switch direction {
        case .Next: return .right
        case .Prev: return .left
        }
    }
    
    var textAlignment : NSTextAlignment {
        // TODO: Deal with RTL once we add iOS 9 support and swap the toolbar buttons depending on layout
        // direction
        switch direction {
        case .Next: return .right
        case .Prev: return .left
        }
    }
    
    private var titleStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: .semiBold, size: .small, color: OEXStyles.shared().primaryBaseColor())
        style.alignment = self.textAlignment
        return style
    }
    
    private var destinationStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralBase())
        style.alignment = self.textAlignment
        return style
    }
}
