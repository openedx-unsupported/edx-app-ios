//
//  Result+JSON.swift
//  edX
//
//  Created by Akiva Leffert on 6/23/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edXCore

extension Result {
    
    init(jsonData : NSData?, error : NSError? = nil, constructor: JSON -> A?) {
        if let data = jsonData,
            json : AnyObject = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()),
            result = constructor(JSON(json)) {
                self = Success(result)
        }
        else {
            self = Failure(error ?? NSError.oex_unknownError())
        }
    }
}
