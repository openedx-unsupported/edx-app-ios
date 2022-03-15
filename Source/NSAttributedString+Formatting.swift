//
//  NSAttributedString+Formatting.swift
//  edX
//
//  Created by Akiva Leffert on 10/15/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension NSAttributedString {
    func addLink(on subString: String, value: Any, foregroundColor: UIColor = OEXStyles.shared().primaryBaseColor(), underline: Bool = false) -> NSAttributedString {
        if string.contains(find: subString) {
            let mutableAttributedString = NSMutableAttributedString(attributedString: self)
            let range = (string as NSString).range(of: subString)
            let attributes = [
                NSAttributedString.Key.link: value,
                NSAttributedString.Key.foregroundColor: foregroundColor,
                NSAttributedString.Key.underlineStyle: underline
                ] as [NSAttributedString.Key : Any]
            mutableAttributedString.addAttributes(attributes, range: range)
            return mutableAttributedString
        }
        
        return self
    }
    
    func addUnderline(foregroundColor: UIColor = OEXStyles.shared().primaryBaseColor()) -> NSAttributedString {
            let mutableAttributedString = NSMutableAttributedString(attributedString: self)
            let range = (string as NSString).range(of: string)
            let attributes = [
                NSAttributedString.Key.foregroundColor: foregroundColor,
                NSAttributedString.Key.underlineStyle: true
                ] as [NSAttributedString.Key : Any]
            mutableAttributedString.addAttributes(attributes, range: range)
            return mutableAttributedString
    }
    
    func applyColor(color: UIColor, on subString: String? = nil, addLineBreak: Bool = false) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: self)
        var mutableString = string
        if addLineBreak, let index = string.range(of: subString ?? string)?.upperBound {
            mutableString.insert("\n", at: index)
            mutableAttributedString.mutableString.setString(mutableString)
        }
       
        let range = mutableString.nsString.range(of: subString ?? string)
        let attributes = [
            NSAttributedString.Key.foregroundColor: color,
        ] as [NSAttributedString.Key : Any]
        mutableAttributedString.addAttributes(attributes, range: range)
        return mutableAttributedString
    }
}

extension OEXTextStyle {

    @objc func apply(f : @escaping (String) -> String) -> ((NSAttributedString) -> NSAttributedString) {
        return {(s : NSAttributedString) in
            let string = f("{__param__}")
            let template = self.attributedString(withText: string)
            return template.oex_format(withParameters: ["__param__" : s])
        }
    }
    
    @nonobjc
    func apply(f : @escaping (String, String) -> String) -> ((NSAttributedString, NSAttributedString) -> NSAttributedString) {
        return {(s1: NSAttributedString, s2: NSAttributedString) in
            let string = f("{__param1__}", "{__param2__}")
            let template = self.attributedString(withText: string)
            return template.oex_format(withParameters: ["__param1__": s1, "__param2__": s2])
        }
    }
    
}

extension String {
    func applyStyle(style : OEXTextStyle) -> NSAttributedString {
        return style.attributedString(withText: self)
    }
    
    var nsString: NSString {
        return NSString(string: self)
    }
}
