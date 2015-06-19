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

public struct NetworkRequest<Out> {
    let method : HTTPMethod
    let path : String // Absolute URL or URL relative to the API base
    let requiresAuth : Bool
    let body : RequestBody
    let query: [String:JSON]
    let deserializer : (NSHTTPURLResponse?, NSData?) -> Result<Out>
    
    public init(method : HTTPMethod,
        path : String,
        requiresAuth : Bool = false,
        body : RequestBody = .EmptyBody,
        query : [String:JSON] = [:],
        deserializer : (NSHTTPURLResponse?, NSData?) -> Result<Out>) {
            self.method = method
            self.path = path
            self.requiresAuth = requiresAuth
            self.body = body
            self.query = query
            self.deserializer = deserializer
    }
}

public struct NetworkResult<Out> {
    public let request: NSURLRequest?
    public let response: NSHTTPURLResponse?
    public let data: Out?
    public let error: NSError?
    
    public init(request : NSURLRequest?, response : NSHTTPURLResponse?, data : Out?, error : NSError?) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
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

    private let authorizationHeaderProvider: AuthorizationHeaderProvider?
    private let baseURL : NSURL
    
    public init(authorizationHeaderProvider: AuthorizationHeaderProvider? = nil, baseURL : NSURL) {
        self.baseURL = baseURL
        self.authorizationHeaderProvider = authorizationHeaderProvider
    }

    public func URLRequestWithRequest<Out>(request : NetworkRequest<Out>) -> Result<NSURLRequest> {
        return NSURL(string: request.path, relativeToURL: baseURL).toResult().flatMap { url -> Result<NSURLRequest> in
            
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
            let (paramRequest, error) = ParameterEncoding.URL.encode(NSURLRequest(URL: url), parameters: queryParams)
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
    
    public func taskForRequest<Out>(request : NetworkRequest<Out>, handler: NetworkResult<Out> -> Void) -> Removable {
        #if DEBUG
            // Don't let network requests happen when testing
            if NSClassFromString("XCTestCase") != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    handler(NetworkResult(request: nil, response: nil, data: nil, error: NSError.oex_courseContentLoadError()))
                }
                return BlockRemovable {}
            }
        #endif
        
        let URLRequest = URLRequestWithRequest(request)
        
        let task = URLRequest.map {URLRequest -> NetworkTask in
            let task = Manager.sharedInstance.request(URLRequest)
            let serializer = { (URLRequest : NSURLRequest, response : NSHTTPURLResponse?, data : NSData?) -> (AnyObject?, NSError?) in
                let result = request.deserializer(response, data)
                return (Box(result.value), result.error)
            }
            task.response(serializer: serializer) { (request, response, object, error) in
                let parsed = (object as? Box<Out?>)?.value
                let result = NetworkResult<Out>(request: request, response: response, data: parsed, error: error)
                handler(result)
            }
            task.resume()
            return NetworkTask(request: task)
        }
        switch task {
        case let .Success(t): return t.value
        case let .Failure(error):
            dispatch_async(dispatch_get_main_queue()) {
                handler(NetworkResult(request: nil, response: nil, data: nil, error: error))
            }
            return BlockRemovable {}
        }
        
    }
    
    func promiseForRequest<Out>(request : NetworkRequest<Out>) -> Promise<Out> {
        return Promise<Out>{(fulfill, reject) -> Void in
            let task = self.taskForRequest(request) {result in
                if let data = result.data {
                    fulfill(data)
                }
                else if let error = result.error {
                    reject(error)
                }
                else {
                    reject(NSError.oex_unknownError())
                }
            }
        }
    }
    
    func streamForRequest<Out>(request : NetworkRequest<Out>, autoCancel : Bool = true) -> Stream<Out> {
        let stream = Sink<NetworkResult<Out>>()
        let task = self.taskForRequest(request) {[weak stream] result in
            stream?.send(result)
        }
        let processedStream = stream.flatMap {(result : NetworkResult<Out>) -> Result<Out> in
            if let data = result.data {
                return Success(data)
            }
            else {
                return Failure(result.error)
            }
        }
        if autoCancel {
            return processedStream.autoCancel(task)
        }
        else {
            return processedStream
        }
    }
}