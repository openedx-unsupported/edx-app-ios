//
//  Profile.swift
//  edX
//
//  Created by Michael Katz on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public class UserProfile {
    
    private enum ProfileFields: String, RawValueExtractable {
        case Image = "profile_image"
        case HasImage = "has_image"
        case ImageURL = "image_url_full"
        case Username = "username"
        case Language = "language"
        case LanguagePreferences = "language_proficiencies"
        case Country = "country"
        case Bio = "bio"
        case Code = "code"
        case ParentalConsent = "requires_parental_consent"
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
        let profileImage = json[ProfileFields.Image]
        if let hasImage = profileImage[ProfileFields.HasImage].bool where hasImage {
            hasProfileImage = true
            imageURL = profileImage[ProfileFields.ImageURL].string
        } else {
            hasProfileImage = false
            imageURL = nil
        }
        username = json[ProfileFields.Username].string
        languageCode = json[ProfileFields.Language].string
        if let languages = json[ProfileFields.LanguagePreferences].array {
            preferredLanguages = languages.flatMap { return $0[ProfileFields.Code].string }
        } else {
            preferredLanguages = nil
        }
        countryCode = json[ProfileFields.Country].string
        bio = json[ProfileFields.Bio].string
        parentalConsent = json[ProfileFields.ParentalConsent].bool
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