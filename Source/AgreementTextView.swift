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

@objc protocol AgreementTextViewDelegate: AnyObject {
    func agreementTextView(_ textView: AgreementTextView, didSelect url: URL)
}

class AgreementTextView: UITextView {
    
    @objc weak var agreementDelegate: AgreementTextViewDelegate?
    
    @objc func setup(for type: AgreementType, config: OEXConfig?) {
        let style = OEXMutableTextStyle(weight: .normal, size: .xxxSmall, color: OEXStyles.shared().neutralXDark())
        style.lineBreakMode = .byWordWrapping
        style.alignment = .left
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
        let agreementText = "\(prefix)\(Strings.Agreement.text(eula: eulaText, tos: tosText, platformName: platformName, privacyPolicy: privacyPolicyText))"
        var attributedString = style.attributedString(withText: agreementText)
        if let eulaUrl = config?.agreementURLsConfig.eulaURL {
            attributedString = attributedString.addLink(on: eulaText, value: eulaUrl)
        }

        if let tosUrl = config?.agreementURLsConfig.tosURL {
            attributedString = attributedString.addLink(on: tosText, value: tosUrl)
        }

        if let privacyPolicyUrl = config?.agreementURLsConfig.privacyPolicyURL {
            attributedString = attributedString.addLink(on: privacyPolicyText, value: privacyPolicyUrl)
        }
        tintColor = OEXStyles.shared().primaryDarkColor()
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
