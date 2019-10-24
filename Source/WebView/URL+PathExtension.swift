//
//  URL+PathExtension.swift
//  edX
//
//  Created by Zeeshan Arif on 7/13/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

extension URL {
    
    var appURLHost: String {
        return host ?? ""
    }
    
    var isValidAppURLScheme: Bool {
        return scheme ?? "" == URIString.appURLScheme.rawValue ? true : false
    }
    
    var queryParameters: [String: Any]? {
        guard let queryString = query else {
            return nil
        }
        var queryParameters = [String: Any]()
        let parameters = queryString.components(separatedBy: "&")
        for parameter in parameters {
            let keyValuePair = parameter.components(separatedBy: "=")
            // Parameter will be ignored if invalid data for keyValuePair
            if keyValuePair.count == 2 {
                let key = keyValuePair[0]
                let value = keyValuePair[1]
                queryParameters[key] = value
            }
        }
        return queryParameters
    }
}
