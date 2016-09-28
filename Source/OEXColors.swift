//
//  OEXColors.swift
//  edX
//
//  Created by Danial Zahid on 8/17/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit

public class OEXColors: NSObject {

    //MARK: - Shared Instance
    public static let sharedInstance = OEXColors()
    
    public var colorsDictionary = [String: AnyObject]()
    
    private override init() {
        super.init()
        colorsDictionary = initializeColorsDictionary()
    }
    
    private func initializeColorsDictionary() -> [String: AnyObject] {
        guard let filePath = NSBundle.mainBundle().pathForResource("colors", ofType: "json") else {
            return fallbackColors
        }
        if let data = NSData(contentsOfFile: filePath) {
            var error : NSError?
            if let json = NSJSONSerialization.oex_JSONObjectWithData(data, error: &error) as? [String: AnyObject] {
                return json
            }
            return fallbackColors
        }
        return fallbackColors
    }
    
    private var fallbackColors: [String: AnyObject] {
        return OEXColorsDataFactory.colors
    }
    
    public func colorForIdentifier(identifier: String) -> UIColor {
        return colorForIdentifier(identifier, alpha: 1.0)
    }
    
    public func colorForIdentifier(identifier: String, alpha: CGFloat) -> UIColor {
        if let hexValue = colorsDictionary[identifier] as? String {
            let color = UIColor(hexString: hexValue, alpha: alpha)
            return color
        }
        return UIColor.whiteColor()
    }
    
}
