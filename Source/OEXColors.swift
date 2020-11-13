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
    @objc public static let sharedInstance = OEXColors()
    @objc public enum ColorsIdentifiers: Int {
        case PrimaryXDarkColor = 1, PrimaryDarkColor, PrimaryBaseColor, PrimaryLightColor, PrimaryXLightColor,
        SecondaryXDarkColor, SecondaryDarkColor, SecondaryBaseColor, SecondaryLightColor, SecondaryXLightColor,
        NeutralBlack, NeutralBlackT, NeutralXDark, NeutralDark, NeutralBase,
        NeutralLight, NeutralXLight, NeutralXXLight, NeutralWhite, NeutralWhiteT,
        UtilitySuccessDark, UtilitySuccessBase, UtilitySuccessLight,
        WarningDark, WarningBase, WarningLight,
        ErrorDark, ErrorBase, ErrorLight,
        BannerColor,
        BrandActionColor,
        BrandAccentColor,
        RandomColor
    }
    
    public var colorsDictionary = [String: AnyObject]()
    
    private override init() {
        super.init()
        colorsDictionary = initializeColorsDictionary()
    }
    
    private func initializeColorsDictionary() -> [String: AnyObject] {
        var filePath: String = ""
        
        if let config = FirebaseRemoteConfiguration.shared.appTheme?.colorConfig,
           let colorFileName = config.name?.components(separatedBy: ".").first, config.enabled,
           let path = Bundle.main.path(forResource: colorFileName, ofType: "json") {
            filePath = path
        } else if let path = Bundle.main.path(forResource: "colors", ofType: "json") {
            filePath = path
        }
        
        if filePath.isEmpty {
            return fallbackColors()
        } else {
            if let data = NSData(contentsOfFile: filePath) {
                var error : NSError?
                
                if let json = JSON(data: data as Data, error: &error).dictionaryObject{
                    return json as [String : AnyObject]
                }
                return fallbackColors()
            }
        }
        
        return fallbackColors()
    }
    
    @discardableResult public func fallbackColors() -> [String: AnyObject] {
        return OEXColorsDataFactory.colors as [String : AnyObject]
    }
    
    @objc public func color(forIdentifier identifier: ColorsIdentifiers) -> UIColor {
        return color(forIdentifier: identifier, alpha: 1.0)
    }
    
    public func color(forIdentifier identifier: ColorsIdentifiers, alpha: CGFloat) -> UIColor {
        if let hexValue = colorsDictionary[getIdentifier(identifier: identifier)] as? String {
            let color = UIColor(hexString: hexValue, alpha: alpha)
            return color
        }

        return UIColor(hexString: getIdentifier(identifier: ColorsIdentifiers.RandomColor), alpha: 1.0)
    }
    
    private func getIdentifier(identifier: ColorsIdentifiers) -> String {
        switch identifier {
        case .BrandActionColor:
            return "brandActionColor"
        case .BrandAccentColor:
            return "brandAccentColor"
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
        case .BannerColor:
            return "bannerColor"
        case .RandomColor:
            fallthrough
        default:
            //Assert to crash on development, and return a random color for distribution
            assert(false, "Could not find the required color in colors.json")
            return "#FABA12"
            
        }
    }
}
