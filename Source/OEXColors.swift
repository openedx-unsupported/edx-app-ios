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
    enum ColorsIdentifiers: String {
        case PrimaryXDarkColor = "primaryXDarkColor"
        case PrimaryDarkColor = "primaryDarkColor"
        case PrimaryBaseColor = "primaryBaseColor"
        case PrimaryLightColor = "primaryLightColor"
        case PrimaryXLightColor = "primaryXLightColor"
        case SecondaryXDarkColor = "secondaryXDarkColor"
        case SecondaryDarkColor = "secondaryDarkColor"
        case SecondaryBaseColor = "secondaryBaseColor"
        case SecondaryLightColor = "secondaryLightColor"
        case SecondaryXLightColor = "secondaryXLightColor"
        case NeutralBlack = "neutralBlack"
        case NeutralBlackT = "neutralBlackT"
        case NeutralXDark = "neutralXDark"
        case NeutralDark = "neutralDark"
        case NeutralBase = "neutralBase"
        case NeutralLight = "neutralLight"
        case NeutralXLight = "neutralXLight"
        case NeutralXXLight = "neutralXXLight"
        case NeutralWhite = "neutralWhite"
        case NeutralWhiteT = "neutralWhiteT"
        case UtilitySuccessDark = "utilitySuccessDark"
        case UtilitySuccessBase = "utilitySuccessBase"
        case UtilitySuccessLight = "utilitySuccessLight"
        case WarningDark = "warningDark"
        case WarningBase = "warningBase"
        case WarningLight = "warningLight"
        case ErrorDark = "errorDark"
        case ErrorBase = "errorBase"
        case ErrorLight = "errorLight"
        case Banner = "banner"
        
        private func toString() -> String {
            return self.rawValue
        }
    }
    
    class func PrimaryXDarkColor() -> NSString { return ColorsIdentifiers.PrimaryXDarkColor.toString() }
    class func PrimaryDarkColor() -> NSString { return ColorsIdentifiers.PrimaryDarkColor.toString() }
    class func PrimaryBaseColor() -> NSString { return ColorsIdentifiers.PrimaryBaseColor.toString() }
    class func PrimaryLightColor() -> NSString { return ColorsIdentifiers.PrimaryLightColor.toString() }
    class func PrimaryXLightColor() -> NSString { return ColorsIdentifiers.PrimaryXLightColor.toString() }
    class func SecondaryXDarkColor() -> NSString { return ColorsIdentifiers.SecondaryXDarkColor.toString() }
    class func SecondaryDarkColor() -> NSString { return ColorsIdentifiers.SecondaryDarkColor.toString() }
    class func SecondaryBaseColor() -> NSString { return ColorsIdentifiers.SecondaryBaseColor.toString() }
    class func SecondaryLightColor() -> NSString { return ColorsIdentifiers.SecondaryLightColor.toString() }
    class func SecondaryXLightColor() -> NSString { return ColorsIdentifiers.SecondaryXLightColor.toString() }
    class func NeutralBlack() -> NSString { return ColorsIdentifiers.NeutralBlack.toString() }
    class func NeutralBlackT() -> NSString { return ColorsIdentifiers.NeutralBlackT.toString() }
    class func NeutralXDark() -> NSString { return ColorsIdentifiers.NeutralXDark.toString() }
    class func NeutralDark() -> NSString { return ColorsIdentifiers.NeutralDark.toString() }
    class func NeutralBase() -> NSString { return ColorsIdentifiers.NeutralBase.toString() }
    class func NeutralLight() -> NSString { return ColorsIdentifiers.NeutralLight.toString() }
    class func NeutralXLight() -> NSString { return ColorsIdentifiers.NeutralXLight.toString() }
    class func NeutralXXLight() -> NSString { return ColorsIdentifiers.NeutralXXLight.toString() }
    class func NeutralWhite() -> NSString { return ColorsIdentifiers.NeutralWhite.toString() }
    class func NeutralWhiteT() -> NSString { return ColorsIdentifiers.NeutralWhiteT.toString() }
    class func UtilitySuccessDark() -> NSString { return ColorsIdentifiers.UtilitySuccessDark.toString() }
    class func UtilitySuccessBase() -> NSString { return ColorsIdentifiers.UtilitySuccessBase.toString() }
    class func UtilitySuccessLight() -> NSString { return ColorsIdentifiers.UtilitySuccessLight.toString() }
    class func WarningDark() -> NSString { return ColorsIdentifiers.WarningDark.toString() }
    class func WarningBase() -> NSString { return ColorsIdentifiers.WarningBase.toString() }
    class func WarningLight() -> NSString { return ColorsIdentifiers.WarningLight.toString() }
    class func ErrorDark() -> NSString { return ColorsIdentifiers.ErrorDark.toString() }
    class func ErrorBase() -> NSString { return ColorsIdentifiers.ErrorBase.toString() }
    class func ErrorLight() -> NSString { return ColorsIdentifiers.ErrorLight.toString() }
    class func Banner() -> NSString { return ColorsIdentifiers.Banner.toString() }
    
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
            
            if let json = JSON(data: data, error: &error).dictionaryObject{
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
        //Assert to crash on development, and return a random color for distribution
        assert(false, "Could not find the required color in colors.json")
        return UIColor(hexString: "#FABA12", alpha: 1.0)
    }
    
}
