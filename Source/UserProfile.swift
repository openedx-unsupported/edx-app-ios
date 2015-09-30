//
//  Profile.swift
//  edX
//
//  Created by Michael Katz on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public class UserProfile {
    
    private enum ProfileFields: String {
        case Image = "profile_image"
        case HasImage = "has_image"
        case ImageURL = "image_url_full"
        case Username = "username"
        case Language = "language"
        case LanguagePreferences = "language_proficiencies"
        case Country = "country"
        case Bio = "bio"
        case ParentalConsent = "requires_parental_consent"
        
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
    let languageCode: String?
    let preferredLanguages: [String]?
    let countryCode: String?
    let bio: String?
    
    private let parentalConsent: Bool?
    
    public init?(json: JSON) {
        if let profileImage = ProfileFields.Image.dictionary(json) {
            hasProfileImage = ProfileFields.HasImage.bool(profileImage) ?? false
            if hasProfileImage {
                imageURL = ProfileFields.ImageURL.string(profileImage)
            } else {
                imageURL = nil
            }
        } else {
            hasProfileImage = false
            imageURL = nil
        }
        username = ProfileFields.Username.string(json)
        languageCode = ProfileFields.Language.string(json)
        if let languages: [NSDictionary] = ProfileFields.LanguagePreferences.array(json) {
            preferredLanguages = languages.map { return $0["code"] as! String }
        } else {
            preferredLanguages = nil
        }
        countryCode = ProfileFields.Country.string(json)
        bio = ProfileFields.Bio.string(json)
        parentalConsent = ProfileFields.ParentalConsent.bool(json)
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
        var code: String?
        if let languageCode = languageCode {
            code = languageCode
        } else {
            if let preferredLanguages = preferredLanguages where preferredLanguages.count > 0 {
                code = preferredLanguages[0]
            }
        }
        return code.flatMap { return NSLocale.currentLocale().displayNameForKey(NSLocaleLanguageCode, value: $0) }
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