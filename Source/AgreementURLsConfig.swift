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
    case supportedlanguages = "SUPPORTED_LANGUAGES"
}

class AgreementURLsConfig : NSObject {
    private var eula: String = ""
    private var tos: String = ""
    private var privacyPolicy: String = ""
    private let spiliter = "webview"
    private var localURLs = false
    var eulaURL: URL? {
        get {
            if localURLs {
                return URL(fileURLWithPath: eula)
            }
            return URL(string: completePath(url: eula))
        }
        set { }
    }

    var tosURL: URL? {
        get {
            if localURLs {
                return URL(fileURLWithPath: tos)
            }
            return URL(string: completePath(url: tos))
        }
        set { }
    }

    var privacyPolicyURL: URL? {
        get {
            if localURLs {
                return URL(fileURLWithPath: privacyPolicy)
            }
            return URL(string: completePath(url: privacyPolicy))
        }
        set { }
    }
    var supportedlanguages: [String] = []

    init(dictionary: [String: AnyObject]) {
        super.init()

        eula = dictionary[AgreementURLsKeys.eulaURL] as? String ?? ""
        tos = dictionary[AgreementURLsKeys.tosURL] as? String ?? ""
        privacyPolicy = dictionary[AgreementURLsKeys.privacyPolicyURL] as? String ?? ""
        supportedlanguages = dictionary[AgreementURLsKeys.supportedlanguages] as? [String] ?? []

        if !eula.isEmpty || !tos.isEmpty || !privacyPolicy.isEmpty { }
        else {
            localURLs = true
            eula = Bundle.main.path(forResource: "MobileAppEula", ofType: "htm") ?? ""
            tos = Bundle.main.path(forResource: "TermsOfServices", ofType: "htm") ?? ""
            privacyPolicy = Bundle.main.path(forResource: "PrivacyPolicy", ofType: "htm") ?? ""
        }
    }

    private func completePath(url: String) -> String {
        let langCode = Locale.current.languageCode ?? ""
        if !supportedlanguages.contains(langCode) {
            return url
        }

        let URL = URL(string: url)
        let host = URL?.host ?? ""

        let components = url.components(separatedBy: host)

        if components.count != 2 {
            return url
        }

        return "\(components.first ?? "")\(host)/\(langCode)\(components.last ?? "")"
    }
}

private let key = "AGREEMENT_URLS"
extension OEXConfig {
    var agreementURLsConfig : AgreementURLsConfig {
        return AgreementURLsConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
