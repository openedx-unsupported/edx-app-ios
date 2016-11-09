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
    @objc enum FontIdentifiers: Int {
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
    
    public func fontForIdentifier(identifier: Int) -> String {
        if let fontName = fontsDictionary[getIdentifier(identifier)] as? String {
            return fontName
        }
        //Assert to crash on development, and return Zapfino font
        assert(false, "Could not find the required font in fonts.json")
        return OEXFontsDataFactory.fonts["irregular"]!
    }
    
    private func getIdentifier(identifier: Int) -> String {
        switch identifier {
        case FontIdentifiers.Regular.rawValue:
            return "regular"
        case FontIdentifiers.SemiBold.rawValue:
            return "semiBold"
        case FontIdentifiers.Bold.rawValue:
            return "bold"
        case FontIdentifiers.Light.rawValue:
            return "light"
        default:
            return "regular"
        }
    }
}

