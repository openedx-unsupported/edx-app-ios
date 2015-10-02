//
//  Profile.swift
//  edX
//
//  Created by Michael Katz on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public class UserProfile {
    
    enum Fields: String {
        case Image = "profile_image"
        case HasImage = "has_image"
        case ImageURL = "image_url_full"
        case Username = "username"
        case LanguagePreferences = "language_proficiencies"
        case Country = "country"
        case Bio = "bio"
        case ParentalConsent = "requires_parental_consent"
        case YearOfBirth = "year_of_birth"
        
        func string(json: JSON) -> String? {
            return json[self.rawValue].string
        }
        
        func string(jsonDict: [String: JSON]) -> String? {
            return jsonDict[self.rawValue]?.string
        }
        func bool(jsonDict: [String: JSON]) -> Bool? {
            return jsonDict[self.rawValue]?.bool
        }
        
        func bool(json: JSON) -> Bool? {
            return json[self.rawValue].bool
        }
        
        func int(json: JSON) -> Int? {
            return json[self.rawValue].int
        }
        
        func dictionary(json: JSON) -> [String: JSON]? {
            return json[self.rawValue].dictionary
        }
        
        func array<T : AnyObject>(json: JSON) -> [T]? {
            return json[self.rawValue].arrayObject as? [T]
        }
    }
    
    let hasProfileImage: Bool
    let imageURL: String?
    let username: String?
    var preferredLanguages: [NSDictionary]?
    var countryCode: String?
    var bio: String?
    var birthYear: Int?
    
    private let parentalConsent: Bool?
    
    var hasUpdates: Bool { return updateDictionary.count > 0 }
    var updateDictionary = [String: AnyObject]()
    
    public init?(json: JSON) {
        if let profileImage = Fields.Image.dictionary(json) {
            hasProfileImage = Fields.HasImage.bool(profileImage) ?? false
            if hasProfileImage {
                imageURL = Fields.ImageURL.string(profileImage)
            } else {
                imageURL = nil
            }
        } else {
            hasProfileImage = false
            imageURL = nil
        }
        username = Fields.Username.string(json)
        if let languages: [NSDictionary] = Fields.LanguagePreferences.array(json) {
            preferredLanguages = languages
        } else {
            preferredLanguages = nil
        }
        countryCode = Fields.Country.string(json)
        bio = Fields.Bio.string(json)
        parentalConsent = Fields.ParentalConsent.bool(json)
        birthYear = Fields.YearOfBirth.int(json)
    }
    
    var languageCode: String? {
        get {
            guard let languages = preferredLanguages where languages.count > 0 else { return nil }
            return languages[0]["code"] as? String
        }
        set {
            guard let code = newValue else { preferredLanguages = nil; return }
            guard preferredLanguages != nil else {
                preferredLanguages = [["code": code]]
                return
            }
            preferredLanguages!.replaceRange(0...0, with: [["code": code]])
        }
    }
}

extension UserProfile { //ViewModel
    func image(networkManager: NetworkManager) -> RemoteImage {
        
        let url = hasProfileImage && imageURL != nil ? imageURL! : ""
        return RemoteImageImpl(url: url, networkManager: networkManager, placeholder: UIImage(named: "avatarPlaceholder"))
    }
    
    var country: String? {
        guard let code = countryCode else { return nil }
        return NSLocale.currentLocale().displayNameForKey(NSLocaleCountryCode, value: code)
    }

    var language: String? {
        return languageCode.flatMap { return NSLocale.currentLocale().displayNameForKey(NSLocaleLanguageCode, value: $0) }
//        get{
//            var code: String?
//            if let languageCode = languageCode {
//                code = languageCode
//            } else {
//                if let preferredLanguages = preferredLanguages where preferredLanguages.count > 0 {
//                    code = preferredLanguages[0]
//                }
//            }
//            return code.flatMap { return NSLocale.currentLocale().displayNameForKey(NSLocaleLanguageCode, value: $0) }
//        }
//        set(code) {
//            guard let code = code else { preferredLanguages = nil; return } //remove the old value(s)
//            
//            if preferredLanguages == nil {
//                preferredLanguages = [code]
//            } else {
//                if preferredLanguages!.contains([code]) {
//                    
//                }
//            }
//            
//        }
    }
    
    var sharingLimitedProfile: Bool {
        return parentalConsent ?? false
    }
}

/*
Profile JSON, to be removed once full profile is loaded (MA-1283)
{
"email" : "staff@example.com",
"year_of_birth" : 1990,
"language_proficiencies" : [

],
"mailing_address" : "",
"is_active" : true,
"level_of_education" : "a",
"bio" : null,
"goals" : "",
"profile_image" : {
"image_url_small" : "https:\/\/mobile-stable.sandbox.edx.org\/static\/images\/default-theme\/default-profile_30.ae6a9ca9b390.png",
"image_url_full" : "https:\/\/mobile-stable.sandbox.edx.org\/static\/images\/default-theme\/default-profile_500.de2c6854f1eb.png",
"image_url_medium" : "https:\/\/mobile-stable.sandbox.edx.org\/static\/images\/default-theme\/default-profile_50.5fb006f96a15.png",
"image_url_large" : "https:\/\/mobile-stable.sandbox.edx.org\/static\/images\/default-theme\/default-profile_120.33ad4f755071.png",
"has_image" : false
},
"date_joined" : "2015-07-16T09:46:38Z",
"username" : "Staff123",
"requires_parental_consent" : false,
"country" : null,
"name" : "Staff",
"gender" : "m"
}
*/