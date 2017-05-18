//
//  Profile.swift
//  edX
//
//  Created by Michael Katz on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore

public class UserProfile {

    public enum ProfilePrivacy: String {
        case Private = "private"
        case Public = "all_users"
    }
    
    enum ProfileFields: String, RawStringExtractable {
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
    }
    
    let hasProfileImage: Bool
    let imageURL: String?
    let username: String?
    var preferredLanguages: [[String: Any]]?
    var countryCode: String?
    var bio: String?
    var birthYear: Int?
    
    let parentalConsent: Bool?
    var accountPrivacy: ProfilePrivacy?
    
    var hasUpdates: Bool { return updateDictionary.count > 0 }
    var updateDictionary = [String: AnyObject]()
    
    public init?(json: JSON) {
        let profileImage = json[ProfileFields.Image]
        if let hasImage = profileImage[ProfileFields.HasImage].bool, hasImage {
            hasProfileImage = true
            imageURL = profileImage[ProfileFields.ImageURL].string
        } else {
            hasProfileImage = false
            imageURL = nil
        }
        username = json[ProfileFields.Username].string
        preferredLanguages = json[ProfileFields.LanguagePreferences].arrayObject as? [[String: Any]]
        countryCode = json[ProfileFields.Country].string
        bio = json[ProfileFields.Bio].string
        birthYear = json[ProfileFields.YearOfBirth].int
        parentalConsent = json[ProfileFields.ParentalConsent].bool
        accountPrivacy = ProfilePrivacy(rawValue: json[ProfileFields.AccountPrivacy].string ?? "")
    }
    
    internal init(username : String, bio : String? = nil, parentalConsent : Bool? = false, countryCode : String? = nil, accountPrivacy : ProfilePrivacy? = nil) {
        self.accountPrivacy = accountPrivacy
        self.username = username
        self.hasProfileImage = false
        self.imageURL = nil
        self.parentalConsent = parentalConsent
        self.bio = bio
        self.countryCode = countryCode
    }
    
    var languageCode: String? {
        get {
            guard let languages = preferredLanguages, languages.count > 0 else { return nil }
            return languages[0]["code"] as? String
        }
        set {
            guard let code = newValue else { preferredLanguages = []; return }
            guard preferredLanguages != nil && preferredLanguages!.count > 0 else {
                preferredLanguages = [["code": code]]
                return
            }
            let cRange = 0...0
            let range = Range(cRange)
            preferredLanguages?.replaceSubrange(range, with: [["code": code]])
        }
    }
}

extension UserProfile { //ViewModel
    func image(networkManager: NetworkManager) -> RemoteImage {
        let placeholder = UIImage(named: "profilePhotoPlaceholder")
        if let url = imageURL, hasProfileImage {
            return RemoteImageImpl(url: url, networkManager: networkManager, placeholder: placeholder, persist: true)
        }
        else {
            return RemoteImageJustImage(image: placeholder)
        }
    }
    
    var country: String? {
        guard let code = countryCode else { return nil }
        return (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: code) ?? ""
    }
    
    var language: String? {
        return languageCode.flatMap { return (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.languageCode, value: $0) }
    }
    
    var sharingLimitedProfile: Bool {
        get {
            return (parentalConsent ?? false) || (accountPrivacy == nil) || (accountPrivacy! == .Private)
        }
    }
    func setLimitedProfile(newValue:Bool) {
        let newStatus: ProfilePrivacy = newValue ? .Private: .Public
        if newStatus != accountPrivacy {
            updateDictionary[ProfileFields.AccountPrivacy.rawValue] = newStatus.rawValue as AnyObject?
        }
        accountPrivacy = newStatus
    }
}
