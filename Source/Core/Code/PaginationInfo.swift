//
//  PaginationInfo.swift
//  edX
//
//  Created by Akiva Leffert on 12/14/15.
//  Copyright © 2015 edX. All rights reserved.
//

public struct PaginationDefaults {
    // Defaults for our APIs
    public static let startPage = 1
    public static let pageSize = 20
    static let pageParam = "page"
    static let pageSizeParam = "page_size"
}

public struct PaginationInfo {
    
    public let totalCount : Int
    public let pageCount : Int
    public let previous : NSURL?
    public let next : NSURL?
    
    public init?(json : JSON) {
        guard let totalCount = json["count"].int else { return nil }
        guard let pageCount = json["num_pages"].int else { return nil }
        self.totalCount = totalCount
        self.pageCount = pageCount
        
        self.previous = json["previous"].string.flatMap { NSURL(string: $0) }
        self.next = json["next"].string.flatMap { NSURL(string: $0) }
    }
    
    public init(totalCount : Int, pageCount : Int, previous : NSURL? = nil, next: NSURL? = nil) {
        self.totalCount = totalCount
        self.pageCount = pageCount
        self.previous = previous
        self.next = next
    }
}

public struct Paginated<A> {
    
    public let pagination : PaginationInfo
    public let value : A
    
    public init?(json : JSON, valueParser : JSON -> A?) {
        // There are two different shapes to our pagination payloads, either embedded under a
        // "pagination" key or flat at the top level.
        // 1. {"pagination": <..pagination fields..>, "results" : <..stuff..>}
        // 2. {"next": ..., "prev": ..., "results" : <..stuff..>}
        // So try both, nested first
        guard let pagination = PaginationInfo(json: json["pagination"]) ?? PaginationInfo(json: json)
            else { return nil }
        guard let value = valueParser(json["results"]) else { return nil }
        self.value = value
        self.pagination = pagination
    }
    
    public init(pagination : PaginationInfo, value : A) {
        self.pagination = pagination
        self.value = value
    }

    public func map<B>(f : A -> B) -> Paginated<B> {
        return Paginated<B>(pagination: pagination, value: f(value))
    }
}

extension NetworkRequest {
    
    public func paginated(page page: Int, pageSize : Int = PaginationDefaults.pageSize) -> NetworkRequest<Paginated<Out>> {
        let paginatedDeserializer : ResponseDeserializer<Paginated<Out>>
        switch deserializer {
        case let .JSONResponse(f):
            paginatedDeserializer = ResponseDeserializer.JSONResponse {(response, json) in
                Paginated(json: json, valueParser: { f(response, $0).value }).toResult(NetworkManager.unknownError)
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
