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
        case Regular = 1, SemiBold, Bold, Light
    }
    
    public var fontsDictionary = [String: AnyObject]()
    
    private override init() {
        super.init()
        fontsDictionary = initializeFontsDictionary()
    }
    
    private func initializeFontsDictionary() -> [String: AnyObject] {
        guard let filePath = NSBundle.mainBundle().pathForResource("fonts", ofType: "json") else {
            return fallbackFonts()
        }
        if let data = NSData(contentsOfFile: filePath) {
            var error : NSError?
            
            if let json = JSON(data: data, error: &error).dictionaryObject{
                return json
            }
            return fallbackFonts()
        }
        return fallbackFonts()
    }
    
    public func fallbackFonts() -> [String: AnyObject] {
        return getFallbackFonts
    }
    
    private var getFallbackFonts: [String: AnyObject] {
        return OEXFontsDataFactory.fonts
    }
    
    public func fontForIdentifier(identifier: FontIdentifiers, size: CGFloat) -> UIFont {
        if let fontName = fontsDictionary[getIdentifier(identifier)] as? String {
            return UIFont(name: fontName, size: size)!
        }
        //Assert to crash on development, and return Zapfino font
        assert(false, "Could not find the required font in fonts.json")
        return UIFont(name:OEXFontsDataFactory.fonts["irregular"]!, size: size)!
    }
    
    private func getIdentifier(identifier: FontIdentifiers) -> String {
        switch identifier {
        case .Regular:
            return "regular"
        case .SemiBold:
            return "semiBold"
        case .Bold:
            return "bold"
        case .Light:
            return "light"
        }
    }
}

