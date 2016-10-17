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

private enum DeserializationResult<Out> {
    case DeserializedResult(value : Result<Out>, original : NSData?)
    case ReauthenticationRequest(AuthenticateRequestCreator, original: NSData?)
}

public typealias AuthenticateRequestCreator = (_networkManager: NetworkManager, _completion: (_success : Bool) -> Void) -> Void

public enum AuthenticationAction {
    case Proceed
    case Authenticate(AuthenticateRequestCreator)
    
    public var isProceed : Bool {
        switch self {
        case .Proceed(_): return true
        case .Authenticate(_): return false
        }
    }
    
    public var isAuthenticate : Bool {
        switch self {
        case .Proceed(_): return false
        case .Authenticate(_): return true
        }
    }
}

public enum ResponseDeserializer<Out> {
    case JSONResponse((NSHTTPURLResponse, JSON) -> Result<Out>)
    case DataResponse((NSHTTPURLResponse, NSData) -> Result<Out>)
    case NoContent(NSHTTPURLResponse -> Result<Out>)
    
    func map<A>(f: Out -> A) -> ResponseDeserializer<A> {
        switch self {
        case let .JSONResponse(d): return .JSONResponse({(request, json) in d(request, json).map(f)})
        case let .DataResponse(d): return .DataResponse({(request, data) in d(request, data).map(f)})
        case let .NoContent(d): return .NoContent({args in d(args).map(f)})
        }
    }
}

public protocol ResponseInterceptor {
    func handleResponse<Out>(result: NetworkResult<Out>) -> Result<Out>
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
    
    public func map<A>(f : Out -> A) -> NetworkRequest<A> {
        return NetworkRequest<A>(method: method, path: path, requiresAuth: requiresAuth, body: body, query: query, headers: additionalHeaders, deserializer: deserializer.map(f))
        
    }
}

extension NetworkRequest: CustomDebugStringConvertible {
    public var debugDescription: String { return "\(self.dynamicType) {\(method):\(path)}" }
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
    
    public static func oex_unknownNetworkError() -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: NetworkManager.Error.UnknownError.rawValue, userInfo: nil)
    }
    
    static func oex_HTTPError(statusCode : Int, userInfo: [NSObject:AnyObject]) -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: statusCode, userInfo: userInfo)
    }
    
    public static func oex_outdatedVersionError() -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: NetworkManager.Error.OutdatedVersionError.rawValue, userInfo: nil)
    }
    
    public var oex_isNoInternetConnectionError : Bool {
        return self.domain == NSURLErrorDomain && (self.code == NSURLErrorNotConnectedToInternet || self.code == NSURLErrorNetworkConnectionLost)
    }
    
    public func errorIsThisType(error: NSError) -> Bool {
        return error.domain == NetworkManager.errorDomain && error.code == self.code
    }
}

public class NetworkManager : NSObject {
    private static let errorDomain = "com.edx.NetworkManager"
    enum Error : Int {
        case UnknownError = -1
        case OutdatedVersionError = -2
    }
    
    public static let NETWORK = "NETWORK" // Logger key
    
    public typealias JSONInterceptor = (_response : NSHTTPURLResponse, _json : JSON) -> Result<JSON>
    public typealias Authenticator = (_response: NSHTTPURLResponse?, _data: NSData) -> AuthenticationAction
    
    public let baseURL : NSURL
    
    private let authorizationHeaderProvider: AuthorizationHeaderProvider?
    private let credentialProvider : URLCredentialProvider?
    private let cache : ResponseCache
    private var jsonInterceptors : [JSONInterceptor] = []
    private var responseInterceptors: [ResponseInterceptor] = []
    public var authenticator : Authenticator?
    
    public init(authorizationHeaderProvider: AuthorizationHeaderProvider? = nil, credentialProvider : URLCredentialProvider? = nil, baseURL : NSURL, cache : ResponseCache) {
        self.authorizationHeaderProvider = authorizationHeaderProvider
        self.credentialProvider = credentialProvider
        self.baseURL = baseURL
        self.cache = cache
    }
    
    public static var unknownError : NSError { return NSError.oex_unknownNetworkError() }
    
    /// Allows you to add a processing pass to any JSON response.
    /// Typically used to check for errors that can be sent by any request
    public func addJSONInterceptor(interceptor : (NSHTTPURLResponse,JSON) -> Result<JSON>) {
        jsonInterceptors.append(interceptor)
    }
    
    public func addResponseInterceptors(interceptor: ResponseInterceptor) {
        responseInterceptors.append(interceptor)
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
                    let raw : AnyObject = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                {
                    let json = JSON(raw)
                    let result = interceptors.reduce(.Success(json)) {(current : Result<JSON>, interceptor : (_response : NSHTTPURLResponse, _json : JSON) -> Result<JSON>) -> Result<JSON> in
                        return current.flatMap {interceptor(_response : response, _json: $0)}
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
                    return .Failure(NSError.oex_HTTPError(response.statusCode, userInfo: userInfo ?? [:]))
                }
                
                return f(response)
            }
        }
        else {
            return .Failure(error)
        }
    }
    
    public func taskForRequest<Out>(networkRequest : NetworkRequest<Out>, handler: NetworkResult<Out> -> Void) -> Removable {
        let URLRequest = URLRequestWithRequest(networkRequest)
        
        let authenticator = self.authenticator
        let interceptors = jsonInterceptors
        let task = URLRequest.map {URLRequest -> NetworkTask in
            Logger.logInfo(NetworkManager.NETWORK, "Request is \(URLRequest)")
            let task = Manager.sharedInstance.request(URLRequest)
            
            let serializer = { (URLRequest : NSURLRequest, response : NSHTTPURLResponse?, data : NSData?) -> (AnyObject?, NSError?) in
                switch authenticator?(_response: response, _data: data!) ?? .Proceed {
                case .Proceed:
                    let result = NetworkManager.deserialize(networkRequest.deserializer, interceptors: interceptors, response: response, data: data, error: NetworkManager.unknownError)
                    return (Box(DeserializationResult.DeserializedResult(value : result, original : data)), result.error)
                case .Authenticate(let authenticateRequest):
                    let result = Box<DeserializationResult<Out>>(DeserializationResult.ReauthenticationRequest(authenticateRequest, original: data))
                    return (result, nil)
                }
            }
            task.response(serializer: serializer) { (request, response, object, error) in
                let parsed = (object as? Box<DeserializationResult<Out>>)?.value
                switch parsed {
                case let .Some(.DeserializedResult(value, original)):
                    let result = NetworkResult<Out>(request: request, response: response, data: value.value, baseData: original, error: error)
                    Logger.logInfo(NetworkManager.NETWORK, "Response is \(response)")
                    handler(result)
                case let .Some(.ReauthenticationRequest(authHandler, originalData)):
                    authHandler(_networkManager: self, _completion: {success in
                        if success {
                            Logger.logInfo(NetworkManager.NETWORK, "Reauthentication, reattempting original request")
                            self.taskForRequest(networkRequest, handler: handler)
                        }
                        else {
                            Logger.logInfo(NetworkManager.NETWORK, "Reauthentication unsuccessful")
                            handler(NetworkResult<Out>(request: request, response: response, data: nil, baseData: originalData, error: error))
                        }
                    })
                case .None:
                    assert(false, "Deserialization failed in an unexpected way")
                    handler(NetworkResult<Out>(request:request, response:response, data: nil, baseData: nil, error: error))
                }
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
            if let response = result.response, request = result.request, data = result.baseData where (persistResponse && data.length > 0) {
                self?.cache.setCacheResponse(response, withData: data, forRequest: request, completion: nil)
            }
            stream?.close()
            stream?.send(result)
        }
        var result : Stream<Out> = stream.flatMap {(result : NetworkResult<Out>) -> Result<Out> in
            return self.handleResponse(result)
        }
        
        if persistResponse {
            result = combineWithPersistentCacheFetch(result, request: request)
        }
        
        if autoCancel {
            result = result.autoCancel(task)
        }
        
        return result
    }
    
    private func handleResponse<Out>(networkResult: NetworkResult<Out>) -> Result<Out> {
        var result:Result<Out>?
        for responseInterceptor in self.responseInterceptors {
            result = responseInterceptor.handleResponse(networkResult)
            if case .None = result {
                break
            }
        }
        
        return result ?? networkResult.data.toResult(NetworkManager.unknownError)
    }
    
}

