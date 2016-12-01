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
    @objc public enum ColorsIdentifiers: Int {
        case PrimaryXDarkColor = 1, PrimaryDarkColor, PrimaryBaseColor, PrimaryLightColor, PrimaryXLightColor,
        SecondaryXDarkColor, SecondaryDarkColor, SecondaryBaseColor, SecondaryLightColor, SecondaryXLightColor,
        NeutralBlack, NeutralBlackT, NeutralXDark, NeutralDark, NeutralBase,
        NeutralLight, NeutralXLight, NeutralXXLight, NeutralWhite, NeutralWhiteT,
        UtilitySuccessDark, UtilitySuccessBase, UtilitySuccessLight,
        WarningDark, WarningBase, WarningLight,
        ErrorDark, ErrorBase, ErrorLight,
        Banner, Random
    }
    
    public var colorsDictionary = [String: AnyObject]()
    
    private override init() {
        super.init()
        colorsDictionary = initializeColorsDictionary()
    }
    
    private func initializeColorsDictionary() -> [String: AnyObject] {
        guard let filePath = NSBundle.mainBundle().pathForResource("colors", ofType: "json") else {
            return fallbackColors()
        }
        if let data = NSData(contentsOfFile: filePath) {
            var error : NSError?
            
            if let json = JSON(data: data, error: &error).dictionaryObject{
                return json
            }
            return fallbackColors()
        }
        return fallbackColors()
    }
    
    public func fallbackColors() -> [String: AnyObject] {
        return OEXColorsDataFactory.colors
    }
    
    public func colorForIdentifier(identifier: ColorsIdentifiers) -> UIColor {
        return colorForIdentifier(identifier, alpha: 1.0)
    }
    
    public func colorForIdentifier(identifier: ColorsIdentifiers, alpha: CGFloat) -> UIColor {
        if let hexValue = colorsDictionary[getIdentifier(identifier)] as? String {
            let color = UIColor(hexString: hexValue, alpha: alpha)
            return color
        }

        return UIColor(hexString: getIdentifier(ColorsIdentifiers.Random), alpha: 1.0)
    }
    
    private func getIdentifier(identifier: ColorsIdentifiers) -> String {
        switch identifier {
        case .PrimaryXDarkColor:
            return "primaryXDarkColor"
        case .PrimaryDarkColor:
            return "primaryDarkColor"
        case .PrimaryBaseColor:
            return "primaryBaseColor"
        case .PrimaryLightColor:
            return "primaryLightColor"
        case .PrimaryXLightColor:
            return "primaryXLightColor"
        case .SecondaryXDarkColor:
            return "secondaryXDarkColor"
        case .SecondaryDarkColor:
            return "secondaryDarkColor"
        case .SecondaryBaseColor:
            return "secondaryBaseColor"
        case .SecondaryLightColor:
            return "secondaryLightColor"
        case .SecondaryXLightColor:
            return "secondaryXLightColor"
        case .NeutralBlack:
            return "neutralBlack"
        case .NeutralBlackT:
            return "neutralBlackT"
        case .NeutralXDark:
            return "neutralXDark"
        case .NeutralDark:
            return "neutralDark"
        case .NeutralBase:
            return "neutralBase"
        case .NeutralLight:
            return "neutralLight"
        case .NeutralXLight:
            return "neutralXLight"
        case .NeutralXXLight:
            return "neutralXXLight"
        case .NeutralWhite:
            return "neutralWhite"
        case .NeutralWhiteT:
            return "neutralWhiteT"
        case .UtilitySuccessDark:
            return "utilitySuccessDark"
        case .UtilitySuccessBase:
            return "utilitySuccessBase"
        case .UtilitySuccessLight:
            return "utilitySuccessLight"
        case .WarningDark:
            return "warningDark"
        case .WarningBase:
            return "warningBase"
        case .WarningLight:
            return "warningLight"
        case .ErrorDark:
            return "errorDark"
        case .ErrorBase:
            return "errorBase"
        case .ErrorLight:
            return "errorLight"
        case .Banner:
            return "banner"
        case .Random:
            fallthrough
        default:
            //Assert to crash on development, and return a random color for distribution
            assert(false, "Could not find the required color in colors.json")
            return "#FABA12"
            
        }
    }
}
