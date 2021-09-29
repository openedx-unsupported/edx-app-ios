//
//  OEXConfig+SingleKeys.swift
//  edX
//
//  Created by Saeed Bashir on 9/28/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
extension OEXConfig {
    var faqURL: String? {
        return string(forKey: "FAQ_URL")
    }

    var deleteAccountURL: String? {
        return string(forKey: "DELETE_ACCOUNT_URL")
    }
}
