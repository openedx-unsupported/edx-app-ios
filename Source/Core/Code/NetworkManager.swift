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
    case jsonBody(JSON)
    case formEncoded([String:String])
    case dataBody(data : Data, contentType: String)
    case emptyBody
}

private enum DeserializationResult<Out> {
    case deserializedResult(value : Result<Out>, original : Data?)
    case reauthenticationRequest(AuthenticateRequestCreator, original: Data?)
}

public typealias AuthenticateRequestCreator = (_ _networkManager: NetworkManager, _ _completion: @escaping (_ _success : Bool) -> Void) -> Void

public enum AuthenticationAction {
    case proceed
    case authenticate(AuthenticateRequestCreator)
    
    public var isProceed : Bool {
        switch self {
        case .proceed(_): return true
        case .authenticate(_): return false
        }
    }
    
    public var isAuthenticate : Bool {
        switch self {
        case .proceed(_): return false
        case .authenticate(_): return true
        }
    }
}

public enum ResponseDeserializer<Out> {
    case jsonResponse((HTTPURLResponse, JSON) -> Result<Out>)
    case dataResponse((HTTPURLResponse, NSData) -> Result<Out>)
    case noContent((HTTPURLResponse) -> Result<Out>)
    
    func map<A>(_ f: @escaping (Out) -> A) -> ResponseDeserializer<A> {
        switch self {
        case let .jsonResponse(d): return .jsonResponse({(request, json) in d(request, json).map(f)})
        case let .dataResponse(d): return .dataResponse({(request, data) in d(request, data).map(f)})
        case let .noContent(d): return .noContent({args in d(args).map(f)})
        }
    }
}

public protocol ResponseInterceptor {
    func handleResponse<Out>(_ result: NetworkResult<Out>) -> Result<Out>
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
                body : RequestBody = .emptyBody,
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
    
    public func map<A>(_ f : @escaping (Out) -> A) -> NetworkRequest<A> {
        return NetworkRequest<A>(method: method, path: path, requiresAuth: requiresAuth, body: body, query: query, headers: additionalHeaders, deserializer: deserializer.map(f))
        
    }
}

extension NetworkRequest: CustomDebugStringConvertible {
    public var debugDescription: String { return "\(type(of: self)) {\(method):\(path)}" }
}


public struct NetworkResult<Out> {
    public let request: URLRequest?
    public let response: HTTPURLResponse?
    public let data: Out?
    public let baseData : Data?
    public let error: NSError?
    
    public init(request : URLRequest?, response : HTTPURLResponse?, data : Out?, baseData : Data?, error : NSError?) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
        self.baseData = baseData
    }
}

open class NetworkTask : Removable {
    let request : Request
    fileprivate init(request : Request) {
        self.request = request
    }
    
    open func remove() {
        request.cancel()
    }
}

@objc public protocol AuthorizationHeaderProvider {
    var authorizationHeaders : [String:String] { get }
}

@objc public protocol URLCredentialProvider {
    func URLCredentialForHost(_ host : NSString) -> URLCredential?
}


@objc public protocol NetworkManagerProvider {
    var networkManager : NetworkManager { get }
}

extension NSError {
    
    public static func oex_unknownNetworkError() -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: NetworkManager.Error.unknownError.rawValue, userInfo: nil)
    }
    
    static func oex_HTTPError(_ statusCode : Int, userInfo: [AnyHashable: Any]) -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: statusCode, userInfo: userInfo)
    }
    
    public static func oex_outdatedVersionError() -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: NetworkManager.Error.outdatedVersionError.rawValue, userInfo: nil)
    }
    
    public var oex_isNoInternetConnectionError : Bool {
        return self.domain == NSURLErrorDomain && (self.code == NSURLErrorNotConnectedToInternet || self.code == NSURLErrorNetworkConnectionLost)
    }
    
    public func errorIsThisType(_ error: NSError) -> Bool {
        return error.domain == NetworkManager.errorDomain && error.code == self.code
    }
}

open class NetworkManager : NSObject {
    fileprivate static let errorDomain = "com.edx.NetworkManager"
    enum Error : Int {
        case unknownError = -1
        case outdatedVersionError = -2
    }
    
    open static let NETWORK = "NETWORK" // Logger key
    
    public typealias JSONInterceptor = (_ _response : HTTPURLResponse, _ _json : JSON) -> Result<JSON>
    public typealias Authenticator = (_ _response: HTTPURLResponse?, _ _data: Data) -> AuthenticationAction
    
    open let baseURL : URL
    
    fileprivate let authorizationHeaderProvider: AuthorizationHeaderProvider?
    fileprivate let credentialProvider : URLCredentialProvider?
    fileprivate let cache : ResponseCache
    fileprivate var jsonInterceptors : [JSONInterceptor] = []
    fileprivate var responseInterceptors: [ResponseInterceptor] = []
    open var authenticator : Authenticator?
    
    public init(authorizationHeaderProvider: AuthorizationHeaderProvider? = nil, credentialProvider : URLCredentialProvider? = nil, baseURL : URL, cache : ResponseCache) {
        self.authorizationHeaderProvider = authorizationHeaderProvider
        self.credentialProvider = credentialProvider
        self.baseURL = baseURL
        self.cache = cache
    }
    
    open static var unknownError : NSError { return NSError.oex_unknownNetworkError() }
    
    /// Allows you to add a processing pass to any JSON response.
    /// Typically used to check for errors that can be sent by any request
    open func addJSONInterceptor(_ interceptor : @escaping (HTTPURLResponse,JSON) -> Result<JSON>) {
        jsonInterceptors.append(interceptor)
    }
    
    open func addResponseInterceptors(_ interceptor: ResponseInterceptor) {
        responseInterceptors.append(interceptor)
    }
    
    open func URLRequestWithRequest<Out>(_ request : NetworkRequest<Out>) -> Result<URLRequest> {
        return URL(string: request.path, relativeTo: baseURL).toResult(NetworkManager.unknownError).flatMap { url -> Result<Foundation.URLRequest> in
            
            let urlRequest = Foundation.URLRequest(url: url)
            if request.query.count == 0 {
                return .success(urlRequest)
            }
            
            var queryParams : [String:String] = [:]
            for (key, value) in request.query {
                if let stringValue = value.rawString(options : JSONSerialization.WritingOptions()) {
                    queryParams[key] = stringValue
                }
            }
            
            // Alamofire has a kind of contorted API where you can encode parameters over URLs
            // or through the POST body, but you can't do both at the same time.
            //
            // So first we encode the get parameters
            let (paramRequest, error) = ParameterEncoding.url.encode(urlRequest, parameters: queryParams as [String : AnyObject]?)
            if let error = error {
                return .failure(error)
            }
            else {
                return .success(paramRequest)
            }
            }
            .flatMap { urlRequest in
                let mutableURLRequest = (urlRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest
                if request.requiresAuth {
                    for (key, value) in self.authorizationHeaderProvider?.authorizationHeaders ?? [:] {
                        mutableURLRequest.setValue(value, forHTTPHeaderField: key)
                    }
                }
                mutableURLRequest.httpMethod = request.method.rawValue
                if let additionalHeaders = request.additionalHeaders {
                    for (header, value) in additionalHeaders {
                        mutableURLRequest.setValue(value, forHTTPHeaderField: header)
                    }
                }
                
                
                // Now we encode the body
                switch request.body {
                case .emptyBody:
                    return .success(mutableURLRequest as URLRequest)
                case let .dataBody(data: data, contentType: contentType):
                    mutableURLRequest.httpBody = data
                    mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
                    return .success(mutableURLRequest as URLRequest)
                case let .formEncoded(dict):
                    let (bodyRequest, error) = ParameterEncoding.url.encode(mutableURLRequest as URLRequest, parameters: dict as [String : AnyObject]?)
                    if let error = error {
                        return .failure(error)
                    }
                    else {
                        return .success(bodyRequest)
                    }
                case let .jsonBody(json):
                    let (bodyRequest, error) = ParameterEncoding.json.encode(mutableURLRequest as URLRequest, parameters: json.dictionaryObject ?? [:] )
                    if let error = error {
                        return .failure(error)
                    }
                    else {
                        let mutableURLRequest = (bodyRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest
                        if let additionalHeaders = request.additionalHeaders {
                            for (header, value) in additionalHeaders {
                                mutableURLRequest.setValue(value, forHTTPHeaderField: header)
                            }
                        }
                        return .success(mutableURLRequest as URLRequest)
                    }
                }
        }
    }
    
    fileprivate static func deserialize<Out>(_ deserializer : ResponseDeserializer<Out>, interceptors : [JSONInterceptor], response : HTTPURLResponse?, data : Data?, error: NSError) -> Result<Out> {
        if let response = response {
            switch deserializer {
            case let .jsonResponse(f):
                if let data = data,
                    let raw : AnyObject = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as AnyObject
                {
                    let json = JSON(raw)
                    let result = interceptors.reduce(.success(json)) {(current : Result<JSON>, interceptor : @escaping (_ _response : HTTPURLResponse, _ _json : JSON) -> Result<JSON>) -> Result<JSON> in
                        return current.flatMap {interceptor(response, $0)}
                    }
                    return result.flatMap {
                        return f(response, $0)
                    }
                }
                else {
                    return .failure(error)
                }
            case let .dataResponse(f):
                return data.toResult(error).flatMap { f(response, $0 as NSData) }
            case let .noContent(f):
                if response.hasErrorResponseCode() { // server error
                    guard let data = data,
                        let raw : AnyObject = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as AnyObject else {
                            return .failure(error)
                    }
                    let userInfo = JSON(raw).object as? [AnyHashable: Any]
                    return .failure(NSError.oex_HTTPError(response.statusCode, userInfo: userInfo ?? [:]))
                }
                
                return f(response)
            }
        }
        else {
            return .failure(error)
        }
    }
    
    @discardableResult open func taskForRequest<Out>(_ networkRequest : NetworkRequest<Out>, handler: @escaping (NetworkResult<Out>) -> Void) -> Removable {
        let URLRequest = URLRequestWithRequest(networkRequest)
        
        let authenticator = self.authenticator
        let interceptors = jsonInterceptors
        let task = URLRequest.map {URLRequest -> NetworkTask in
            Logger.logInfo(NetworkManager.NETWORK, "Request is \(URLRequest)")
            let task = Manager.sharedInstance.request(URLRequest)
            
            let serializer = { (URLRequest : Foundation.URLRequest, response : HTTPURLResponse?, data : Data?) -> (AnyObject?, NSError?) in
                switch authenticator?(response, data!) ?? .proceed {
                case .proceed:
                    let result = NetworkManager.deserialize(networkRequest.deserializer, interceptors: interceptors, response: response, data: data, error: NetworkManager.unknownError)
                    return (Box(DeserializationResult.deserializedResult(value : result, original : data)), result.error)
                case .authenticate(let authenticateRequest):
                    let result = Box<DeserializationResult<Out>>(DeserializationResult.reauthenticationRequest(authenticateRequest, original: data))
                    return (result, nil)
                }
            }
            task.response(serializer: serializer) { (request, response, object, error) in
                let parsed = (object as? Box<DeserializationResult<Out>>)?.value
                switch parsed {
                case let .some(.deserializedResult(value, original)):
                    let result = NetworkResult<Out>(request: request, response: response, data: value.value, baseData: original, error: error)
                    Logger.logInfo(NetworkManager.NETWORK, "Response is \(String(describing: response))")
                    handler(result)
                case let .some(.reauthenticationRequest(authHandler, originalData)):
                    authHandler(self, {success in
                        if success {
                            Logger.logInfo(NetworkManager.NETWORK, "Reauthentication, reattempting original request")
                            self.taskForRequest(networkRequest, handler: handler)
                        }
                        else {
                            Logger.logInfo(NetworkManager.NETWORK, "Reauthentication unsuccessful")
                            handler(NetworkResult<Out>(request: request, response: response, data: nil, baseData: originalData, error: error))
                        }
                    })
                case .none:
                    assert(false, "Deserialization failed in an unexpected way")
                    handler(NetworkResult<Out>(request:request, response:response, data: nil, baseData: nil, error: error))
                }
            }
            if let
                host = URLRequest.url?.host,
                let credential = self.credentialProvider?.URLCredentialForHost(host as NSString)
            {
                task.authenticate(usingCredential: credential)
            }
            task.resume()
            return NetworkTask(request: task)
        }
        switch task {
        case let .success(t): return t
        case let .failure(error):
            DispatchQueue.main.async {
                handler(NetworkResult(request: nil, response: nil, data: nil, baseData : nil, error: error))
            }
            return BlockRemovable {}
        }
        
    }
    
    fileprivate func combineWithPersistentCacheFetch<Out>(_ stream : OEXStream<Out>, request : NetworkRequest<Out>) -> OEXStream<Out> {
        if let URLRequest = URLRequestWithRequest(request).value {
            let cacheStream = Sink<Out>()
            let interceptors = jsonInterceptors
            cache.fetchCacheEntryWithRequest(URLRequest, completion: {(entry : ResponseCacheEntry?) -> Void in
                
                if let entry = entry {
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                        [weak cacheStream] in
                        let result = NetworkManager.deserialize(request.deserializer, interceptors: interceptors, response: entry.response, data: entry.data, error: NetworkManager.unknownError)
                        DispatchQueue.main.async {[weak cacheStream] in
                            cacheStream?.close()
                            cacheStream?.send(result)
                        }
                    }
                }
                else {
                    cacheStream.close()
                    if let error = stream.error, error.oex_isNoInternetConnectionError {
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
    
    open func streamForRequest<Out>(_ request : NetworkRequest<Out>, persistResponse : Bool = false, autoCancel : Bool = true) -> OEXStream<Out> {
        let stream = Sink<NetworkResult<Out>>()
        let task = self.taskForRequest(request) {[weak stream, weak self] result in
            if let response = result.response, let request = result.request, let data = result.baseData, (persistResponse && data.count > 0) {
                self?.cache.setCacheResponse(response, withData: data, forRequest: request, completion: nil)
            }
            stream?.close()
            stream?.send(result)
        }
        var result : OEXStream<Out> = stream.flatMap {(result : NetworkResult<Out>) -> Result<Out> in
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
    
    fileprivate func handleResponse<Out>(_ networkResult: NetworkResult<Out>) -> Result<Out> {
        var result:Result<Out>?
        for responseInterceptor in self.responseInterceptors {
            result = responseInterceptor.handleResponse(networkResult)
            if case .none = result {
                break
            }
        }
        
        return result ?? networkResult.data.toResult(NetworkManager.unknownError)
    }
    
}

