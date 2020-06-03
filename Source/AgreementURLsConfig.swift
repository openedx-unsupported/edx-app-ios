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
    var eulaURL: URL? = nil
    var tosURL: URL? = nil
    var privacyPolicyURL: URL? = nil
    
    init(dictionary: [String: AnyObject]) {
        let eulaURL = dictionary[AgreementURLsKeys.eulaURL] as? String
        let tosURL = dictionary[AgreementURLsKeys.tosURL] as? String
        let privacyPolicyURL = dictionary[AgreementURLsKeys.privacyPolicyURL] as? String

        if eulaURL != nil || tosURL != nil || privacyPolicyURL != nil {
            if let eulaURL = eulaURL, !eulaURL.isEmpty {
                self.eulaURL = URL(string: eulaURL)
            }

            if let tosURL = tosURL, !tosURL.isEmpty {
                self.tosURL = URL(string: tosURL)
            }

            if let privacyPolicyURL = privacyPolicyURL, !privacyPolicyURL.isEmpty {
                self.privacyPolicyURL = URL(string: privacyPolicyURL)
            }
        }
        else {
            self.eulaURL = Bundle.main.url(forResource: "MobileAppEula", withExtension: "htm")
            self.tosURL = Bundle.main.url(forResource: "TermsOfServices", withExtension: "htm")
            self.privacyPolicyURL = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "htm")
        }
    }
}

private let key = "AGREEMENT_URLS"
extension OEXConfig {
    var agreementURLsConfig : AgreementURLsConfig {
        return AgreementURLsConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
