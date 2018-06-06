//
//  AgreementURLsConfig.swift
//
//  Created by Afzal Wali on 20/May/2018
//  OpenSource Contribution
//

import Foundation

fileprivate enum AgreementURLsKeys: String, RawStringExtractable {
    case eulaURL = "EULA_URL"
    case tosURL = "TOS_URL"
    case privacyPolicyURL = "PRIVACY_POLICY_URL"
}

class AgreementURLsConfig : NSObject {
    let eulaURL: URL?
    let tosURL: URL?
    let privacyPolicyURL: URL?
    
    init(dictionary: [String: AnyObject]) {
        if let eulaURL = dictionary[AgreementURLsKeys.eulaURL] as? String {
            self.eulaURL = URL(string: eulaURL)
        }
        else {
            eulaURL = Bundle.main.url(forResource: "MobileAppEula", withExtension: "htm")
        }
        
        if let tosURL = dictionary[AgreementURLsKeys.tosURL] as? String {
            self.tosURL = URL(string: tosURL)
        }
        else {
            tosURL = Bundle.main.url(forResource: "TermsOfServices", withExtension: "htm")
        }
        
        if let privacyPolicyURL = dictionary[AgreementURLsKeys.privacyPolicyURL] as? String {
            self.privacyPolicyURL = URL(string: privacyPolicyURL)
        }
        else {
            privacyPolicyURL = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "htm")
        }
    }
}

private let key = "AGREEMENT_URLS"
extension OEXConfig {
    var agreementURLsConfig : AgreementURLsConfig {
        return AgreementURLsConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
