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
        case primaryXXLightColor, primaryXLightColor, primaryLightColor, primaryBaseColor, primaryDarkColor,
        secondaryDarkColor, secondaryBaseColor,
        accentAColor, accentBColor,
        neutralBlackT, neutralBlack, neutralXXDark, neutralXDark, neutralDark, neutralBase,
        neutralWhiteT, neutralWhite, neutralXLight, neutralLight,
        successXXLight, successXLight, successLight, successBase, successXDark, successDark,
        warningXXLight, warningXLight, warningLight, warningBase, warningDark, warningXDark,
        errorXXLight, errorXLight, errorLight, errorBase, errorDark, errorXDark,
        infoXXLight, infoXLight, infoLight, infoBase, infoDark, infoXDark,
        randomColor
    }
    
    public var colorsDictionary = [String: AnyObject]()
    
    private override init() {
        super.init()
        colorsDictionary = initializeColorsDictionary()
    }
    
    private func initializeColorsDictionary() -> [String: AnyObject] {
        let filePath: String = Bundle.main.path(forResource: "colors", ofType: "json") ?? ""
        
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

        return UIColor(hexString: getIdentifier(identifier: ColorsIdentifiers.randomColor), alpha: 1.0)
    }
    
    private func getIdentifier(identifier: ColorsIdentifiers) -> String {
        switch identifier {
        case .primaryXXLightColor:
            return "primaryXXLightColor"
        case .primaryXLightColor:
            return "primaryXLightColor"
        case .primaryLightColor:
            return "primaryLightColor"
        case .primaryBaseColor:
            return "primaryBaseColor"
        case .primaryDarkColor:
            return "primaryDarkColor"
        case .secondaryBaseColor:
            return "secondaryBaseColor"
        case .secondaryDarkColor:
            return "secondaryDarkColor"
        case .accentAColor:
            return "accentAColor"
        case .accentBColor:
            return "accentBColor"
        case .neutralBlackT:
            return "neutralBlackT"
        case .neutralBlack:
            return "neutralBlack"
        case .neutralXXDark:
            return "neutralXXDark"
        case .neutralXDark:
            return "neutralXDark"
        case .neutralDark:
            return "neutralDark"
        case .neutralBase:
            return "neutralBase"
        case .neutralWhiteT:
            return "neutralWhiteT"
        case .neutralWhite:
            return "neutralWhite"
        case .neutralXLight:
            return "neutralXLight"
        case .neutralLight:
            return "neutralLight"
        case .successXXLight:
            return "successXXLight"
        case .successXLight:
            return "successXLight"
        case .successLight:
            return "successLight"
        case .successBase:
            return "successBase"
        case .successDark:
            return "successDark"
        case .warningXXLight:
            return "warningXXLight"
        case .warningXLight:
            return "warningXLight"
        case .warningLight:
            return "warningLight"
        case .warningBase:
            return "warningBase"
        case .warningDark:
            return "warningDark"
        case .warningXDark:
            return "warningXDark"
        case .errorXXLight:
            return "errorXXLight"
        case .errorXLight:
            return "errorXLight"
        case .errorLight:
            return "errorLight"
        case .errorBase:
            return "errorBase"
        case .errorDark:
            return "errorDark"
        case .errorXDark:
            return "errorXDark"
        case .infoXXLight:
            return "infoXXLight"
        case .infoXLight:
            return "infoXLight"
        case .infoLight:
            return "infoLight"
        case .infoBase:
            return "infoBase"
        case .infoDark:
            return "infoDark"
        case .infoXDark:
            return "infoXDark"
        case .randomColor:
            fallthrough
        default:
            //Assert to crash on development, and return a random color for distribution
            assert(false, "Could not find the required color in colors.json")
            return "#FABA12"
            
        }
    }
}
