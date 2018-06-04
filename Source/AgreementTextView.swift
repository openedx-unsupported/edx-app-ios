//
//  AgreementTextView.swift
//  edX
//
//  Created by Zeeshan Arif on 4/25/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

@objc enum AgreementType: UInt {
    case signIn,
         signUp
}

@objc protocol AgreementTextViewDelegate: class {
    func agreementTextView(_ textView: AgreementTextView, didSelect url: URL)
}

class AgreementTextView: UITextView {
    
    weak var agreementDelegate: AgreementTextViewDelegate?
    
    @objc func setup(for type: AgreementType, config: OEXConfig?) {
        let style = OEXMutableTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralDark())
        style.lineBreakMode = .byWordWrapping
        style.alignment = .center
        let platformName = config?.platformName() ?? ""
        let prefix: String
        switch type {
        case .signIn:
            prefix = Strings.Agreement.textPrefixSignin
            break
        case .signUp:
            prefix = Strings.Agreement.textPrefixSignup
            break
        }
        let eulaText = Strings.Agreement.linkTextEula(platformName: platformName)
        let tosText = Strings.Agreement.linkTextTos(platformName: platformName)
        let privacyPolicyText = Strings.Agreement.linkTextPrivacyPolicy
        let agreementText = "\(prefix)\(Strings.Agreement.text(eula: eulaText, tos: tosText, privacyPolicy: privacyPolicyText))"
        var attributedString = style.attributedString(withText: agreementText)
        if let eulaUrl = config?.agreementURLsConfig.eulaURL,
            let tosUrl = config?.agreementURLsConfig.tosURL,
            let privacyPolicyUrl = config?.agreementURLsConfig.privacyPolicyURL {
            attributedString = attributedString.addLink(on: eulaText, value: eulaUrl)
            attributedString = attributedString.addLink(on: tosText, value: tosUrl)
            attributedString = attributedString.addLink(on: privacyPolicyText, value: privacyPolicyUrl)
        }
        attributedText = attributedString
        isUserInteractionEnabled = true
        isScrollEnabled = false
        isEditable = false
        delegate = self
    }
}

extension AgreementTextView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        agreementDelegate?.agreementTextView(self, didSelect: URL)
        return false
    }
}
