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
    enum FontIdentifiers: String {
        case Regular = "regular"
        case SemiBold = "semiBold"
        case Bold = "bold"
        case Light = "light"
        
        private func toString() -> String {
            return self.rawValue
        }
    }
    
    class func Regular() -> NSString {
        return FontIdentifiers.Regular.toString()
    }
    
    class func SemiBold() -> NSString {
        return FontIdentifiers.SemiBold.toString()
    }
    
    class func Bold() -> NSString {
        return FontIdentifiers.Bold.toString()
    }
    
    class func Light() -> NSString {
        return FontIdentifiers.Light.toString()
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
    
    public func fontForIdentifier(identifier: String) -> String {
        if let fontName = fontsDictionary[identifier] as? String {
            return fontName
        }
        //Assert to crash on development, and return Zapfino font
        assert(false, "Could not find the required font in fonts.json")
        return OEXFontsDataFactory.fonts["irregular"]!
    }
}

