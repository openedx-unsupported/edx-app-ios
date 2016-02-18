//
//  PaginationInfo.swift
//  edX
//
//  Created by Akiva Leffert on 12/14/15.
//  Copyright © 2015 edX. All rights reserved.
//

public struct PaginationDefaults {
    // Defaults for our APIs
    static let startPage = 1
    static let pageSize = 20
    static let pageParam = "page"
    static let pageSizeParam = "page_size"
}

public struct PaginationInfo {
    
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

extension NetworkRequest {
    
    public func paginated(page page: Int, pageSize : Int = PaginationDefaults.pageSize) -> NetworkRequest<Paginated<Out>> {
        let paginatedDeserializer : ResponseDeserializer<Paginated<Out>>
        switch deserializer {
        case let .JSONResponse(f):
            paginatedDeserializer = ResponseDeserializer.JSONResponse {(response, json) in
                Paginated(json: json, valueParser: { f(response, $0).value }).toResult()
            }
        case let .DataResponse(f):
            paginatedDeserializer = ResponseDeserializer.DataResponse {(response, data) in
                return f(response, data).map {
                    assert(false, "Can only convert a request to paginated when it uses ResponseDeserializer.JSONResponse")
                    return Paginated(pagination: PaginationInfo(totalCount: 1, pageCount: 1), value: $0)
                }
            }
        case let .NoContent(f):
            paginatedDeserializer = ResponseDeserializer.NoContent {response in
                return f(response).map {
                    assert(false, "Can only convert a request to paginated when it uses ResponseDeserializer.JSONResponse")
                    return Paginated(pagination: PaginationInfo(totalCount: 1, pageCount: 1), value: $0)
                }
            }
        }
        
        var paginatedQuery = query
        paginatedQuery[PaginationDefaults.pageSizeParam] = JSON(pageSize)
        paginatedQuery[PaginationDefaults.pageParam] = JSON(page)
        
        return NetworkRequest<Paginated<Out>> (
            method: method,
            path: path,
            requiresAuth: requiresAuth,
            body: body,
            query: paginatedQuery,
            headers: additionalHeaders,
            deserializer: paginatedDeserializer
        )
    }
}
