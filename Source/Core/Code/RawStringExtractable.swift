//
//  RawStringExtactable.swift
//  edX
//
//  Created by Akiva Leffert on 10/2/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public protocol RawStringExtractable {
    var rawValue : String { get }
}

public extension JSON {
    
    subscript(key : RawStringExtractable) -> JSON {
        return self[key.rawValue]
    }

}

public protocol DictionaryExtractionExtension {
    associatedtype Key
    associatedtype Value
    subscript(key: Key) -> Value? { get }
}

extension Dictionary: DictionaryExtractionExtension {}

public extension DictionaryExtractionExtension where Self.Key == String {
    
    subscript(key : RawStringExtractable) -> Value? {
        return self[key.rawValue]
    }
    
}