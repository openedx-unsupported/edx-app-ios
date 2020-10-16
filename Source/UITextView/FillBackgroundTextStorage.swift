//
//  FillBackgroundTextStorage.swift
//  edX
//
//  Created by Muhammad Umer on 08/10/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

class FillBackgroundTextStorage: NSTextStorage {
    private var attributedString: NSMutableAttributedString
    
    override init(attributedString attrStr: NSAttributedString) {
        attributedString = NSMutableAttributedString(attributedString: attrStr)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var string: String {
        return attributedString.string
    }
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return attributedString.attributes(at: location, effectiveRange: range)
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        attributedString.replaceCharacters(in: range, with: str)
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: str.count - range.length)
        endEditing()
    }
    
    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        beginEditing()
        attributedString.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    func drawBackground(range: NSRange, backgroundColor: UIColor, foregroundColor: UIColor) {
        addAttributes([.backgroundColor: backgroundColor, .foregroundColor: foregroundColor], range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }
}
