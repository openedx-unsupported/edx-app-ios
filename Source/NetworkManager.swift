//
//  CourseOutline.swift
//  edX
//
//  Created by Jake Lim on 5/09/15.
//  Copyright (c) 2015 edX. All rights reserved.
//


import Foundation

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

public enum RequestBody {
    case JSONBody(JSON)
    case DataBody(data : NSData, contentType : String)
    case EmptyBody
}

public enum ResponseDeserializer<Out> {
    case JSONResponse((NSHTTPURLResponse, JSON) -> Result<Out>)
    case DataResponse((NSHTTPURLResponse, NSData) -> Result<Out>)
    case NoContent(NSHTTPURLResponse -> Result<Out>)
}

public struct NetworkRequest<Out> {
    let method : HTTPMethod
    let path : String // Absolute URL or URL relative to the API base
    let requiresAuth : Bool
    let body : RequestBody
    let query: [String:JSON]
    let deserializer : ResponseDeserializer<Out>
    
    public init(method : HTTPMethod,
        path : String,
        requiresAuth : Bool = false,
        body : RequestBody = .EmptyBody,
        query : [String:JSON] = [:],
        deserializer : ResponseDeserializer<Out>) {
            self.method = method
            self.path = path
            self.requiresAuth = requiresAuth
            self.body = body
            self.query = query
            self.deserializer = deserializer
    }
}

extension NetworkRequest: DebugPrintable {
    public var debugDescription: String { return "\(_stdlib_getDemangledTypeName(self.dynamicType)) {\(method):\(path)}" }
}


public struct NetworkResult<Out> {
    public let request: NSURLRequest?
    public let response: NSHTTPURLResponse?
    public let data: Out?
    public let baseData : NSData?
    public let error: NSError?
    
    public init(request : NSURLRequest?, response : NSHTTPURLResponse?, data : Out?, baseData : NSData?, error : NSError?) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
        self.baseData = baseData
    }
}

public class NetworkTask : Removable {
    let request : Request
    private init(request : Request) {
        self.request = request
    }
    
    public func remove() {
        request.cancel()
    }
}

@objc public protocol AuthorizationHeaderProvider {
    var authorizationHeaders : [String:String] { get }
}

public class NetworkManager : NSObject {
    public typealias JSONInterceptor = (response : NSHTTPURLResponse, json : JSON) -> Result<JSON>

    private let authorizationHeaderProvider: AuthorizationHeaderProvider?
    private let baseURL : NSURL
    private let cache : ResponseCache
    private var jsonInterceptors : [JSONInterceptor] = []
    
    public init(authorizationHeaderProvider: AuthorizationHeaderProvider? = nil, baseURL : NSURL, cache : ResponseCache) {
        self.authorizationHeaderProvider = authorizationHeaderProvider
        self.baseURL = baseURL
        self.cache = cache
    }
    
    /// Allows you to add a processing pass to any JSON response.
    /// Typically used to check for errors that can be sent by any request
    public func addJSONInterceptor(interceptor : (response : NSHTTPURLResponse, json : JSON) -> Result<JSON>) {
        jsonInterceptors.append(interceptor)
    }

    public func URLRequestWithRequest<Out>(request : NetworkRequest<Out>) -> Result<NSURLRequest> {
        return NSURL(string: request.path, relativeToURL: baseURL).toResult().flatMap { url -> Result<NSURLRequest> in
            
            let URLRequest = NSURLRequest(URL: url)
            if request.query.count == 0 {
                return Success(URLRequest)
            }
            
            var queryParams : [String:String] = [:]
            for (key, value) in request.query {
                value.rawString(options : NSJSONWritingOptions()).map {stringValue -> Void in
                    queryParams[key] = stringValue
                }
            }
            
            // Alamofire has a kind of contorted API where you can encode parameters over URLs
            // or through the POST body, but you can't do both at the same time.
            //
            // So first we encode the get parameters
            let (paramRequest, error) = ParameterEncoding.URL.encode(URLRequest, parameters: queryParams)
            if let error = error {
                return Failure(error)
            }
            else {
                return Success(paramRequest)
            }
        }
        .flatMap { URLRequest in
            let mutableURLRequest = URLRequest.mutableCopy() as! NSMutableURLRequest
            if request.requiresAuth {
                for (key, value) in self.authorizationHeaderProvider?.authorizationHeaders ?? [:] {
                    mutableURLRequest.setValue(value, forHTTPHeaderField: key)
                }
            }
            mutableURLRequest.HTTPMethod = request.method.rawValue
            
            // Now we encode the body
            switch request.body {
            case .EmptyBody:
                return Success(mutableURLRequest)
            case let .DataBody(data: data, contentType: contentType):
                mutableURLRequest.HTTPBody = data
                mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
                return Success(mutableURLRequest)
            case let .JSONBody(json):
                let (bodyRequest, error) = ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json.dictionaryObject ?? [:])
                
                if let error = error {
                    return Failure(error)
                }
                else {
                    return Success(bodyRequest)
                }
            }
            
        }
    }
    
    private static func deserialize<Out>(deserializer : ResponseDeserializer<Out>, interceptors : [JSONInterceptor], response : NSHTTPURLResponse?, data : NSData?) -> Result<Out> {
        if let response = response {
            switch deserializer {
            case let .JSONResponse(f):
                if let data = data,
                    raw : AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: nil)
                {
                    let json = JSON(raw)
                    let result = reduce(interceptors, Success(json)) {(current : Result<JSON>, interceptor : (response : NSHTTPURLResponse, json : JSON) -> Result<JSON>) -> Result<JSON> in
                        return current.flatMap {interceptor(response : response, json: $0)}
                    }
                    return result.flatMap {
                        return f(response, $0)
                    }
                }
                else {
                    return Failure(NSError.oex_unknownError())
                }
            case let .DataResponse(f):
                return data.toResult().flatMap { f(response, $0) }
            case let .NoContent(f):
                return f(response)
            }
        }
        else {
            return Failure()
        }
    }
    
    public func taskForRequest<Out>(request : NetworkRequest<Out>, handler: NetworkResult<Out> -> Void) -> Removable {
        let URLRequest = URLRequestWithRequest(request)
        
        let interceptors = jsonInterceptors
        let task = URLRequest.map {URLRequest -> NetworkTask in
            let task = Manager.sharedInstance.request(URLRequest)
            let serializer = { (URLRequest : NSURLRequest, response : NSHTTPURLResponse?, data : NSData?) -> (AnyObject?, NSError?) in
                let result = NetworkManager.deserialize(request.deserializer, interceptors: interceptors, response: response, data: data)
                return (Box((value : result.value, original : data)), result.error)
            }
            task.response(serializer: serializer) { (request, response, object, error) in
                let parsed = (object as? Box<(value : Out?, original : NSData?)>)?.value
                let result = NetworkResult<Out>(request: request, response: response, data: parsed?.value, baseData: parsed?.original, error: error)
                handler(result)
            }
            task.resume()
            return NetworkTask(request: task)
        }
        switch task {
        case let .Success(t): return t.value
        case let .Failure(error):
            dispatch_async(dispatch_get_main_queue()) {
                handler(NetworkResult(request: nil, response: nil, data: nil, baseData : nil, error: error))
            }
            return BlockRemovable {}
        }
        
    }
    
    private func combineWithPersistentCacheFetch<Out>(stream : Stream<Out>, request : NetworkRequest<Out>) -> Stream<Out> {
        if let URLRequest = URLRequestWithRequest(request).value {
            let cacheStream = Sink<Out>()
            let interceptors = jsonInterceptors
            cache.fetchCacheEntryWithRequest(URLRequest, completion: {(entry : ResponseCacheEntry?) -> Void in
                
                if let entry = entry {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak cacheStream] in
                        let result = NetworkManager.deserialize(request.deserializer, interceptors: interceptors, response: entry.response, data: entry.data)
                        dispatch_async(dispatch_get_main_queue()) {[weak cacheStream] in
                            cacheStream?.close()
                            cacheStream?.send(result)
                        }
                    })
                }
                else {
                    cacheStream.close()
                }
            })
            return stream.cachedByStream(cacheStream)
        }
        else {
            return stream
        }
    }
    
    public func streamForRequest<Out>(request : NetworkRequest<Out>, persistResponse : Bool = false, autoCancel : Bool = true) -> Stream<Out> {
        let stream = Sink<NetworkResult<Out>>()
        let task = self.taskForRequest(request) {[weak stream, weak self] result in
            if let response = result.response, request = result.request where persistResponse {
                self?.cache.setCacheResponse(response, withData: result.baseData, forRequest: request, completion: nil)
            }
            stream?.close()
            stream?.send(result)
        }
        var result : Stream<Out> = stream.flatMap {[weak self] (result : NetworkResult<Out>) -> Result<Out> in
            return result.data.toResult(result.error)
        }
        
        if persistResponse {
            result = combineWithPersistentCacheFetch(result, request: request)
        }
        
        if autoCancel {
            result = result.autoCancel(task)
        }
        
        return result
    }

}


extension NetworkManager {
    func addStandardInterceptors() {
        addJSONInterceptor { (response, json) -> Result<JSON> in
            if let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode) where statusCode.is4xx {
                if json["has_access"].bool == false {
                    let access = OEXCoursewareAccess(dictionary : json.dictionaryObject)
                    return Failure(OEXCoursewareAccessError(coursewareAccess: access, displayInfo: nil))
                }
                return Success(json)
            }
            else {
                return Success(json)
            }
        }
    }
}
