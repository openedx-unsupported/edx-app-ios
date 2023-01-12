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
    case cookiePolicyURL = "COOKIE_POLICY_URL"
    case dataSellConsentURL = "DATA_SELL_CONSENT_URL"

    var bundlePath: String {
        switch self {
        case .eulaURL:
            return "MobileAppEula"
        case .tosURL:
            return "TermsOfServices"
        case .privacyPolicyURL:
            return "PrivacyPolicy"
        default:
            return ""
        }
    }
}

class AgreementURLsConfig : NSObject {
    private var eula: String = ""
    private var tos: String = ""
    private var privacyPolicy: String = ""
    private var cookiePolicy: String = ""
    private var dataSellConsent: String = ""
    private let spiliter = "webview"
    private var localURLs = false

    var eulaURL: URL? {
        return localURLs ? URL(fileURLWithPath: eula) : URL(string: completePath(url: eula))
    }

    var tosURL: URL? {
        return localURLs ? URL(fileURLWithPath: tos) : URL(string: completePath(url: tos))
    }

    var privacyPolicyURL: URL? {
        return localURLs ? URL(fileURLWithPath: privacyPolicy) : URL(string: completePath(url: privacyPolicy))
    }
    
    var cookiePolicyURL: URL? {
        return URL(string: cookiePolicy)
    }
    
    var dataSellConsentURL: URL? {
        return URL(string: dataSellConsent)
    }

    private var supportedLanguages: [String] = []
    
    var enabledForProfile: Bool {
        return !privacyPolicy.isEmpty || !cookiePolicy.isEmpty || !dataSellConsent.isEmpty
    }

    init(dictionary: [String: AnyObject]) {
        super.init()

        eula = dictionary[AgreementURLsKeys.eulaURL] as? String ?? ""
        tos = dictionary[AgreementURLsKeys.tosURL] as? String ?? ""
        privacyPolicy = dictionary[AgreementURLsKeys.privacyPolicyURL] as? String ?? ""
        cookiePolicy = dictionary[AgreementURLsKeys.cookiePolicyURL] as? String ?? ""
        dataSellConsent = dictionary[AgreementURLsKeys.dataSellConsentURL] as? String ?? ""
        supportedLanguages = dictionary[AgreementURLsKeys.supportedlanguages] as? [String] ?? []

        if !eula.isEmpty || !tos.isEmpty || !privacyPolicy.isEmpty { }
        else {
            localURLs = true
            eula = Bundle.main.path(forResource: AgreementURLsKeys.eulaURL.bundlePath, ofType: "htm") ?? ""
            tos = Bundle.main.path(forResource: AgreementURLsKeys.tosURL.bundlePath, ofType: "htm") ?? ""
            privacyPolicy = Bundle.main.path(forResource: AgreementURLsKeys.privacyPolicyURL.bundlePath, ofType: "htm") ?? ""
        }
    }

    private func completePath(url: String) -> String {
        let langCode = Locale.current.languageCode ?? ""
        if !supportedLanguages.contains(langCode) {
            return url
        }

        let URL = URL(string: url)
        let host = URL?.host ?? ""

        let components = url.components(separatedBy: host)

        if components.count != 2 {
            return url
        }

        if let firstComponent = components.first, let lastComponent = components.last {
            return "\(firstComponent)\(host)/\(langCode)\(lastComponent)"
        }

        return url
    }
}

private let key = "AGREEMENT_URLS"
extension OEXConfig {
    var agreementURLsConfig : AgreementURLsConfig {
        return AgreementURLsConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
