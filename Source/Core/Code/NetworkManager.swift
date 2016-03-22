//
//  CourseOutline.swift
//  edX
//
//  Created by Jake Lim on 5/09/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
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
    case FormEncoded([String:String])
    case DataBody(data : NSData, contentType: String)
    case EmptyBody
}

public enum ResponseDeserializer<Out> {
    case JSONResponse((NSHTTPURLResponse, JSON) -> Result<Out>)
    case DataResponse((NSHTTPURLResponse, NSData) -> Result<Out>)
    case NoContent(NSHTTPURLResponse -> Result<Out>)
}

public struct NetworkRequest<Out> {
    public let method : HTTPMethod
    public let path : String // Absolute URL or URL relative to the API base
    public let requiresAuth : Bool
    public let body : RequestBody
    public let query: [String:JSON]
    public let deserializer : ResponseDeserializer<Out>
    public let additionalHeaders: [String: String]?
    
    public init(method : HTTPMethod,
        path : String,
        requiresAuth : Bool = false,
        body : RequestBody = .EmptyBody,
        query : [String:JSON] = [:],
        headers: [String: String]? = nil,
        deserializer : ResponseDeserializer<Out>) {
            self.method = method
            self.path = path
            self.requiresAuth = requiresAuth
            self.body = body
            self.query = query
            self.deserializer = deserializer
            self.additionalHeaders = headers
    }
}

extension NetworkRequest: CustomDebugStringConvertible {
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

@objc public protocol URLCredentialProvider {
    func URLCredentialForHost(host : NSString) -> NSURLCredential?
}


@objc public protocol NetworkManagerProvider {
    var networkManager : NetworkManager { get }
}

extension NSError {

    static var oex_unknownNetworkError : NSError {
        return NSError(domain: NetworkManager.errorDomain, code: NetworkManager.Error.UnknownError.rawValue, userInfo: nil)
    }

    static func oex_HTTPError(statusCode statusCode : Int, userInfo: [NSObject:AnyObject]) -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: statusCode, userInfo: userInfo)
    }

    public var oex_isUnknownNetworkError : Bool {
        return self.domain == NetworkManager.errorDomain && self.code == NetworkManager.Error.UnknownError.rawValue
    }

    public var oex_isNoInternetConnectionError : Bool {
        return self.domain == NSURLErrorDomain && (self.code == NSURLErrorNotConnectedToInternet || self.code == NSURLErrorNetworkConnectionLost)
    }
}

public class NetworkManager : NSObject {
    private static let errorDomain = "com.edx.NetworkManager"
    enum Error : Int {
        case UnknownError = -1
    }

    public static let NETWORK = "NETWORK" // Logger key

    public typealias JSONInterceptor = (response : NSHTTPURLResponse, json : JSON) -> Result<JSON>

    public let baseURL : NSURL

    private let authorizationHeaderProvider: AuthorizationHeaderProvider?
    private let credentialProvider : URLCredentialProvider?
    private let cache : ResponseCache
    private var jsonInterceptors : [JSONInterceptor] = []
    
    public init(authorizationHeaderProvider: AuthorizationHeaderProvider? = nil, credentialProvider : URLCredentialProvider? = nil, baseURL : NSURL, cache : ResponseCache) {
        self.authorizationHeaderProvider = authorizationHeaderProvider
        self.credentialProvider = credentialProvider
        self.baseURL = baseURL
        self.cache = cache
    }

    public static var unknownError : NSError { return NSError.oex_unknownNetworkError }

    /// Allows you to add a processing pass to any JSON response.
    /// Typically used to check for errors that can be sent by any request
    public func addJSONInterceptor(interceptor : (response : NSHTTPURLResponse, json : JSON) -> Result<JSON>) {
        jsonInterceptors.append(interceptor)
    }

    public func URLRequestWithRequest<Out>(request : NetworkRequest<Out>) -> Result<NSURLRequest> {
        return NSURL(string: request.path, relativeToURL: baseURL).toResult(NetworkManager.unknownError).flatMap { url -> Result<NSURLRequest> in
            
            let URLRequest = NSURLRequest(URL: url)
            if request.query.count == 0 {
                return .Success(URLRequest)
            }
            
            var queryParams : [String:String] = [:]
            for (key, value) in request.query {
                if let stringValue = value.rawString(options : NSJSONWritingOptions()) {
                    queryParams[key] = stringValue
                }
            }
            
            // Alamofire has a kind of contorted API where you can encode parameters over URLs
            // or through the POST body, but you can't do both at the same time.
            //
            // So first we encode the get parameters
            let (paramRequest, error) = ParameterEncoding.URL.encode(URLRequest, parameters: queryParams)
            if let error = error {
                return .Failure(error)
            }
            else {
                return .Success(paramRequest)
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
            if let additionalHeaders = request.additionalHeaders {
                for (header, value) in additionalHeaders {
                    mutableURLRequest.setValue(value, forHTTPHeaderField: header)
                }
            }

            
            // Now we encode the body
            switch request.body {
            case .EmptyBody:
                return .Success(mutableURLRequest)
            case let .DataBody(data: data, contentType: contentType):
                mutableURLRequest.HTTPBody = data
                mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
                return .Success(mutableURLRequest)
            case let .FormEncoded(dict):
                let (bodyRequest, error) = ParameterEncoding.URL.encode(mutableURLRequest, parameters: dict)
                if let error = error {
                    return .Failure(error)
                }
                else {
                    return .Success(bodyRequest)
                }
            case let .JSONBody(json):
                let (bodyRequest, error) = ParameterEncoding.JSON.encode(mutableURLRequest, parameters: json.dictionaryObject ?? [:])
                if let error = error {
                    return .Failure(error)
                }
                else {
                    let mutableURLRequest = bodyRequest.mutableCopy() as! NSMutableURLRequest
                    if let additionalHeaders = request.additionalHeaders {
                        for (header, value) in additionalHeaders {
                            mutableURLRequest.setValue(value, forHTTPHeaderField: header)
                        }
                    }
                    return .Success(mutableURLRequest)
                }
            }
            
        }
    }
    
    private static func deserialize<Out>(deserializer : ResponseDeserializer<Out>, interceptors : [JSONInterceptor], response : NSHTTPURLResponse?, data : NSData?, error: NSError) -> Result<Out> {
        if let response = response {
            switch deserializer {
            case let .JSONResponse(f):
                if let data = data,
                    raw : AnyObject = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                {
                    let json = JSON(raw)
                    let result = interceptors.reduce(.Success(json)) {(current : Result<JSON>, interceptor : (response : NSHTTPURLResponse, json : JSON) -> Result<JSON>) -> Result<JSON> in
                        return current.flatMap {interceptor(response : response, json: $0)}
                    }
                    return result.flatMap {
                        return f(response, $0)
                    }
                }
                else {
                    return .Failure(error)
                }
            case let .DataResponse(f):
                return data.toResult(error).flatMap { f(response, $0) }
            case let .NoContent(f):
                if response.hasErrorResponseCode() { // server error
                    guard let data = data,
                        raw : AnyObject = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) else {
                            return .Failure(error)
                    }
                    let userInfo = JSON(raw).object as? [NSObject : AnyObject]
                    return .Failure(NSError.oex_HTTPError(statusCode: response.statusCode, userInfo: userInfo ?? [:]))
                }
                
                return f(response)
            }
        }
        else {
            return .Failure(error)
        }
    }
    
    public func taskForRequest<Out>(request : NetworkRequest<Out>, handler: NetworkResult<Out> -> Void) -> Removable {
        let URLRequest = URLRequestWithRequest(request)
        
        let interceptors = jsonInterceptors
        let task = URLRequest.map {URLRequest -> NetworkTask in
            Logger.logInfo(NetworkManager.NETWORK, "Request is \(URLRequest)")
            let task = Manager.sharedInstance.request(URLRequest)
            let serializer = { (URLRequest : NSURLRequest, response : NSHTTPURLResponse?, data : NSData?) -> (AnyObject?, NSError?) in
                let result = NetworkManager.deserialize(request.deserializer, interceptors: interceptors, response: response, data: data, error: NetworkManager.unknownError)
                return (Box((value : result.value, original : data)), result.error)
            }
            task.response(serializer: serializer) { (request, response, object, error) in
                let parsed = (object as? Box<(value : Out?, original : NSData?)>)?.value
                let result = NetworkResult<Out>(request: request, response: response, data: parsed?.value, baseData: parsed?.original, error: error)
                Logger.logInfo(NetworkManager.NETWORK, "Response is \(response)")
                handler(result)
            }
            if let
                host = URLRequest.URL?.host,
                credential = self.credentialProvider?.URLCredentialForHost(host)
            {
                task.authenticate(usingCredential: credential)
            }
            task.resume()
            return NetworkTask(request: task)
        }
        switch task {
        case let .Success(t): return t
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
                        let result = NetworkManager.deserialize(request.deserializer, interceptors: interceptors, response: entry.response, data: entry.data, error: NetworkManager.unknownError)
                        dispatch_async(dispatch_get_main_queue()) {[weak cacheStream] in
                            cacheStream?.close()
                            cacheStream?.send(result)
                        }
                    })
                }
                else {
                    cacheStream.close()
                    if let error = stream.error where error.oex_isNoInternetConnectionError {
                        cacheStream.send(error)
                    }
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
        var result : Stream<Out> = stream.flatMap {(result : NetworkResult<Out>) -> Result<Out> in
            return result.data.toResult(result.error ?? NetworkManager.unknownError)
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

