//
//  PaginationInfo.swift
//  edX
//
//  Created by Akiva Leffert on 12/14/15.
//  Copyright © 2015 edX. All rights reserved.
//

public struct PaginationInfo {
    
    static let startPage = 1
    static let standardPageParam = "page"
    
    let totalCount : Int
    let pageCount : Int
    let previous : NSURL?
    let next : NSURL?
    
    init?(json : JSON) {
        guard let totalCount = json["count"].int else { return nil }
        guard let pageCount = json["num_pages"].int else { return nil }
        self.totalCount = totalCount
        self.pageCount = pageCount
        
        self.previous = json["previous"].string.flatMap { NSURL(string: $0) }
        self.next = json["next"].string.flatMap { NSURL(string: $0) }
    }
    
    init(totalCount : Int, pageCount : Int, previous : NSURL? = nil, next: NSURL? = nil) {
        self.totalCount = totalCount
        self.pageCount = pageCount
        self.previous = previous
        self.next = next
    }
}

public struct Paginated<A> {
    
    let pagination : PaginationInfo
    let value : A
    
    init?(json : JSON, valueParser : JSON -> A?) {
        guard let pagination = PaginationInfo(json: json["pagination"]) else { return nil }
        guard let value = valueParser(json["results"]) else { return nil }
        self.value = value
        self.pagination = pagination
    }
    
    init(pagination : PaginationInfo, value : A) {
        self.pagination = pagination
        self.value = value
    }
}