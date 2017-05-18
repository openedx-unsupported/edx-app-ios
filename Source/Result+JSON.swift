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
    
    init(jsonData : NSData?, error : NSError? = nil, constructor: (JSON) -> A?) {
        if let data = jsonData,
            let json : AnyObject = try? JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions()) as AnyObject,
            let result = constructor(JSON(json)) {
                self = Success(v: result)
        }
        else {
            self = Failure(e: error ?? NSError.oex_unknownError())
        }
    }
}
