//
//  Dictionary+Functional.swift
//  edX
//
//  Created by Akiva Leffert on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension Dictionary {
    
    init(elements : [(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
    
    func mapValues<T>(f : Value -> T) -> [Key:T] {
        var result : [Key:T] = [:]
        for (key, value) in self {
            result[key] = f(value)
        }
        return result
    }
}