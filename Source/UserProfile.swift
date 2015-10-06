//
//  Profile.swift
//  edX
//
//  Created by Michael Katz on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public class UserProfile {

    private enum ProfilePrivacy: String {
        case Private = "private"
        case Public = "all_users"
    }
    
    enum ProfileFields: String, RawValueExtractable {
        case Image = "profile_image"
        case HasImage = "has_image"
        case ImageURL = "image_url_full"
        case Username = "username"
        case LanguagePreferences = "language_proficiencies"
        case Country = "country"
        case Bio = "bio"
        case YearOfBirth = "year_of_birth"
        case ParentalConsent = "requires_parental_consent"
        case AccountPrivacy = "account_privacy"
        
        case LimitedProfile = "limited_profile" //computed field - determined by age & privacy api
        
    }
    
    let hasProfileImage: Bool
    let imageURL: String?
    let username: String?
    var preferredLanguages: [NSDictionary]?
    var countryCode: String?
    var bio: String?
    var birthYear: Int?
    
    private let parentalConsent: Bool?
    private let accountPrivacy: ProfilePrivacy?
    
    var hasUpdates: Bool { return updateDictionary.count > 0 }
    var updateDictionary = [String: AnyObject]()
    
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
        preferredLanguages = json[ProfileFields.LanguagePreferences].arrayObject as? [NSDictionary]
        countryCode = json[ProfileFields.Country].string
        bio = json[ProfileFields.Bio].string
        birthYear = json[ProfileFields.YearOfBirth].int
        parentalConsent = json[ProfileFields.ParentalConsent].bool
        accountPrivacy = ProfilePrivacy(rawValue: json[ProfileFields.AccountPrivacy].string ?? "")
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
    }
    
    var sharingLimitedProfile: Bool {
        get {
            return (parentalConsent ?? false) || (accountPrivacy == nil) || (accountPrivacy! == .Private)
        }
    }
    func setLimitedProfile(newValue:Bool) {
        let newStatus: ProfilePrivacy = newValue ? .Private: .Public
        if newStatus != accountPrivacy {
            updateDictionary[ProfileFields.AccountPrivacy.rawValue] = newStatus.rawValue
        }
    }
}

/*
Profile JSON, to be removed once full profile is loaded (MA-1283)
{
"email" : "mkatz+1@edx.org",
"year_of_birth" : 1952,
"language_proficiencies" : [
{
"code" : "bs"
}
],
"mailing_address" : "",
"is_active" : true,
"level_of_education" : null,
"bio" : "My name is Ozymandias, king of kings: Look on my works, ye Mighty, and despair!",
"goals" : "",
"profile_image" : {
"image_url_small" : "https:\/\/dkxj5n08iyd6q.cloudfront.net\/52.0.146.10\/037131c252eb0fa8e689c5652b27b469_30.jpg?v=1444156954",
"image_url_full" : "https:\/\/dkxj5n08iyd6q.cloudfront.net\/52.0.146.10\/037131c252eb0fa8e689c5652b27b469_500.jpg?v=1444156954",
"image_url_medium" : "https:\/\/dkxj5n08iyd6q.cloudfront.net\/52.0.146.10\/037131c252eb0fa8e689c5652b27b469_50.jpg?v=1444156954",
"image_url_large" : "https:\/\/dkxj5n08iyd6q.cloudfront.net\/52.0.146.10\/037131c252eb0fa8e689c5652b27b469_120.jpg?v=1444156954",
"has_image" : true
},
"account_privacy" : "all_users",
"date_joined" : "2015-09-28T18:44:31Z",
"username" : "MartyTheParty",
"requires_parental_consent" : false,
"country" : "VN",
"name" : "Marty Party",
"gender" : null
}*/