//
//  ApiUrlVersionConfig.swift
//  edX
//
//  Created by Salman on 08/07/2019.
//  Copyright © 2019 edX. All rights reserved.
//

import UIKit

fileprivate enum ApiUrlVersionKeys: String, RawStringExtractable {
    case blocks = "BLOCKS"
}

class ApiUrlVersionConfig: NSObject {

    let blocksAPIVersion: String?
    
    init(dictionary: [String: AnyObject]) {
        blocksAPIVersion = dictionary[ApiUrlVersionKeys.blocks] as? String
        super.init()
    }
}

private let key = "URL_API_VERSION"
extension OEXConfig {
    @objc var apiUrlConfig: ApiUrlVersionConfig {
        return ApiUrlVersionConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
