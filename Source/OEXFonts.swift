//
//  OEXFonts.swift
//  edX
//
//  Created by José Antonio González on 11/2/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit

public class OEXFonts: NSObject {
    
    //MARK: - Shared Instance
    public static let sharedInstance = OEXFonts()
    @objc public enum FontIdentifiers: Int {
        case Regular = 1, Italic, SemiBold, SemiBoldItalic, Bold, BoldItalic, Light, LightItalic, ExtraBold, ExtraBoldItalic, Irregular
    }
    
    public var fontsDictionary = [String: AnyObject]()
    
    private override init() {
        super.init()
        fontsDictionary = initializeFontsDictionary()
    }
    
    private func initializeFontsDictionary() -> [String: AnyObject] {
        guard let filePath = Bundle.main.path(forResource: "fonts", ofType: "json") else {
            return fallbackFonts()
        }
        if let data = NSData(contentsOfFile: filePath) {
            var error : NSError?
            
            if let json = JSON(data: data as Data, error: &error).dictionaryObject{
                return json as [String : AnyObject]
            }
        }
        return fallbackFonts()
    }
    
    @discardableResult public func fallbackFonts() -> [String: AnyObject] {
        return OEXFontsDataFactory.fonts as [String : AnyObject]
    }
    
    public func font(forIdentifier identifier: FontIdentifiers, size: CGFloat) -> UIFont {
        let pointSize = dynamicTextSize(for: size)
        if let fontName = fontsDictionary[getIdentifier(identifier: identifier)] as? String {
                return UIFont(descriptor: UIFontDescriptor(name: fontName, size: pointSize), size: pointSize)
        }

        return UIFont(descriptor: UIFontDescriptor(name: getIdentifier(identifier: FontIdentifiers.Irregular), size: pointSize), size: pointSize)
    }
    
    func dynamicSizeAdjustmentFactor(with style: UIFontTextStyle) -> CGFloat {
        switch style {
        case .caption2, .caption1, .footnote, .callout, .title3:
            return 2
        case .subheadline:
            return 3
        case .body, .title2:
            return 1
        case .title1:
            return 4
        default:
            return 2
        }
    }
    
    func dynamicTextSize(for size: CGFloat) -> CGFloat {
        let style = textStyle(for: size)
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let pointSize = fontDescriptor.pointSize - dynamicSizeAdjustmentFactor(with: style)
        
        switch style {
        case .caption2:
            return pointSize > 19 ? 19 : pointSize
        case .caption1:
            return pointSize > 20 ? 20 : pointSize
        case .footnote:
            return pointSize > 21 ? 21 : pointSize
        case .subheadline:
            return pointSize > 24 ? 24 : pointSize
        case .callout:
            return pointSize > 24 ? 24 : pointSize
        case .body:
            return pointSize > 24 ? 24 : pointSize
        case .title3:
            return pointSize > 28 ? 28 : pointSize
        case .title2:
            return pointSize > 29 ? 29 : pointSize
        case .title1:
            return pointSize > 40 ? 40 : pointSize
        default:
            return 24
        }
    }
    
    func textStyle(for size: CGFloat) -> UIFontTextStyle {
        switch size {
        case 9:
            return .caption2
        case 10:
            return .caption1
        case 11:
            return .footnote
        case 12:
            return .subheadline
        case 14:
            return .callout
        case 16:
            return .body
        case 18:
            return .title3
        case 21:
            return .title2
        case 24:
            return .title1
        case 28:
            return .title1
        default:
            return .callout
        }
    }
    
    private func getIdentifier(identifier: FontIdentifiers) -> String {
        switch identifier {
        case .Regular:
            return "regular"
        case .Italic:
            return "italic"
        case .SemiBold:
            return "semiBold"
        case .SemiBoldItalic:
            return "semiBoldItalic"
        case .Bold:
            return "bold"
        case .BoldItalic:
            return "boldItalic"
        case .Light:
            return "light"
        case .LightItalic:
            return "lightItalic"
        case .ExtraBold:
            return "extraBold"
        case .ExtraBoldItalic:
            return "extraBoldItalic"
        case .Irregular:
            fallthrough
        default:
            //Assert to crash on development, and return Zapfino font
            assert(false, "Could not find the required font in fonts.json")
            return "Zapfino"
        }
    }
}

