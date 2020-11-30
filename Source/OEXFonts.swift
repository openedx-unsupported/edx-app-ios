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
    @objc public static let sharedInstance = OEXFonts()
    @objc public enum FontIdentifiers: Int {
        case Regular = 1, Italic, SemiBold, SemiBoldItalic, Bold, BoldItalic, Light, LightItalic, ExtraBold, ExtraBoldItalic, Irregular
    }
    
    public var fontsDictionary = [String: AnyObject]()
    
    private override init() {
        super.init()
        fontsDictionary = initializeFontsDictionary()
    }
    
    private func initializeFontsDictionary() -> [String: AnyObject] {
        let filePath: String = Bundle.main.path(forResource: "fonts", ofType: "json") ?? ""
        
        if filePath.isEmpty {
            return fallbackFonts()
        } else {
            if let data = NSData(contentsOfFile: filePath) {
                var error : NSError?
                
                if let json = JSON(data: data as Data, error: &error).dictionaryObject {
                    return json as [String : AnyObject]
                }
            }
        }
        
        return fallbackFonts()
    }
    
    @discardableResult public func fallbackFonts() -> [String: AnyObject] {
        return OEXFontsDataFactory.fonts as [String : AnyObject]
    }
    
    private func fontName(identifier: FontIdentifiers) -> String {
        guard let fontName = fontsDictionary[getIdentifier(identifier: identifier)] as? String  else {
            return getIdentifier(identifier: FontIdentifiers.Irregular)
        }
        return fontName
    }
    
    @objc public func font(for identifier: FontIdentifiers, size: CGFloat) -> UIFont {
        
        let preferredFontDescriptor = UIFont().preferredDescriptor(name: fontName(identifier: identifier), size: size)
        let preferredFontSize = UIFont().preferredFontSize(size: size)
        
        return UIFont(descriptor: preferredFontDescriptor, size: preferredFontSize)
    }

    @objc public func font(for identifier: FontIdentifiers, size: CGFloat, dynamicTypeSupported: Bool) -> UIFont {
        if dynamicTypeSupported {
            return font(for: identifier, size: size)
        }

        if let fontName = fontsDictionary[getIdentifier(identifier: identifier)] as? String {
            return UIFont(name: fontName, size: size)!
        }

        return UIFont(name:getIdentifier(identifier: FontIdentifiers.Irregular), size: size)!
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

