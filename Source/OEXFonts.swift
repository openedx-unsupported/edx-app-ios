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
    
    public var fontsDictionary = [String: AnyObject]()
    
    private override init() {
        super.init()
        fontsDictionary = initializeFontsDictionary()
    }
    
    private func initializeFontsDictionary() -> [String: AnyObject] {
        guard let filePath = NSBundle.mainBundle().pathForResource("fonts", ofType: "json") else {
            return fallbackFonts
        }
        if let data = NSData(contentsOfFile: filePath) {
            var error : NSError?
            
            if let json = JSON(data: data, error: &error).dictionaryObject{
                return json
            }
            return fallbackFonts
        }
        return fallbackFonts
    }
    
    private var fallbackFonts: [String: AnyObject] {
        return OEXFontsDataFactory.fonts
    }
    
    public func fontForIdentifier(identifier: String) -> String {
        if let fontName = fontsDictionary[identifier] as? String {
            return fontName
        }
        //Assert to crash on development, and return a regular OpenSans
        assert(false, "Could not find the required font in fonts")
        return OEXFontsDataFactory.fonts["regular"]!
    }
    
}

