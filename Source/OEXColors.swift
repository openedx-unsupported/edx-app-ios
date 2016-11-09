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
    @objc enum ColorsIdentifiers: Int {
        case PrimaryXDarkColor = 1, PrimaryDarkColor, PrimaryBaseColor, PrimaryLightColor, PrimaryXLightColor,
        SecondaryXDarkColor, SecondaryDarkColor, SecondaryBaseColor, SecondaryLightColor, SecondaryXLightColor,
        NeutralBlack, NeutralBlackT, NeutralXDark, NeutralDark, NeutralBase,
        NeutralLight, NeutralXLight, NeutralXXLight, NeutralWhite, NeutralWhiteT,
        UtilitySuccessDark, UtilitySuccessBase, UtilitySuccessLight,
        WarningDark, WarningBase, WarningLight,
        ErrorDark, ErrorBase, ErrorLight,
        Banner
    }
    
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
    
    public func colorForIdentifier(identifier: Int) -> UIColor {
        return colorForIdentifier(identifier, alpha: 1.0)
    }
    
    public func colorForIdentifier(identifier: Int, alpha: CGFloat) -> UIColor {
        if let hexValue = colorsDictionary[getIdentifier(identifier)] as? String {
            let color = UIColor(hexString: hexValue, alpha: alpha)
            return color
        }
        //Assert to crash on development, and return a random color for distribution
        assert(false, "Could not find the required color in colors.json")
        return UIColor(hexString: "#FABA12", alpha: 1.0)
    }
    
    private func getIdentifier(identifier: Int) -> String {
        switch identifier {
        case ColorsIdentifiers.PrimaryXDarkColor.rawValue:
            return "primaryXDarkColor"
        case ColorsIdentifiers.PrimaryDarkColor.rawValue:
            return "primaryDarkColor"
        case ColorsIdentifiers.PrimaryBaseColor.rawValue:
            return "primaryBaseColor"
        case ColorsIdentifiers.PrimaryLightColor.rawValue:
            return "primaryLightColor"
        case ColorsIdentifiers.PrimaryXLightColor.rawValue:
            return "primaryXLightColor"
        case ColorsIdentifiers.SecondaryXDarkColor.rawValue:
            return "secondaryXDarkColor"
        case ColorsIdentifiers.SecondaryDarkColor.rawValue:
            return "secondaryDarkColor"
        case ColorsIdentifiers.SecondaryBaseColor.rawValue:
            return "secondaryBaseColor"
        case ColorsIdentifiers.SecondaryLightColor.rawValue:
            return "secondaryLightColor"
        case ColorsIdentifiers.SecondaryXLightColor.rawValue:
            return "secondaryXLightColor"
        case ColorsIdentifiers.NeutralBlack.rawValue:
            return "neutralBlack"
        case ColorsIdentifiers.NeutralBlackT.rawValue:
            return "neutralBlackT"
        case ColorsIdentifiers.NeutralXDark.rawValue:
            return "neutralXDark"
        case ColorsIdentifiers.NeutralDark.rawValue:
            return "neutralDark"
        case ColorsIdentifiers.NeutralBase.rawValue:
            return "neutralBase"
        case ColorsIdentifiers.NeutralLight.rawValue:
            return "neutralLight"
        case ColorsIdentifiers.NeutralXLight.rawValue:
            return "neutralXLight"
        case ColorsIdentifiers.NeutralXXLight.rawValue:
            return "neutralXXLight"
        case ColorsIdentifiers.NeutralWhite.rawValue:
            return "neutralWhite"
        case ColorsIdentifiers.NeutralWhiteT.rawValue:
            return "neutralWhiteT"
        case ColorsIdentifiers.UtilitySuccessDark.rawValue:
            return "utilitySuccessDark"
        case ColorsIdentifiers.UtilitySuccessBase.rawValue:
            return "utilitySuccessBase"
        case ColorsIdentifiers.UtilitySuccessLight.rawValue:
            return "utilitySuccessLight"
        case ColorsIdentifiers.WarningDark.rawValue:
            return "warningDark"
        case ColorsIdentifiers.WarningBase.rawValue:
            return "warningBase"
        case ColorsIdentifiers.WarningLight.rawValue:
            return "warningLight"
        case ColorsIdentifiers.ErrorDark.rawValue:
            return "errorDark"
        case ColorsIdentifiers.ErrorBase.rawValue:
            return "errorBase"
        case ColorsIdentifiers.ErrorLight.rawValue:
            return "errorLight"
        case ColorsIdentifiers.Banner.rawValue:
            return "banner"
        default:
            return "primaryBaseColor"
        }
    }
}
