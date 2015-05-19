//
//  CourseOutline.swift
//  edX
//
//  Created by Jake Lim on 5/09/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

/*
 * A sample usage of NetworkManager class

NetworkManager().getWithURL("http://your.server/api/path") {
    (result: NetworkResult<NSData>) -> () in // here, instead of NSData, also NSDictionary, NSArray, NSString, NSNumber, or NSNull is allowed. NetworkManager will handle appropriate conversion

    if result.error != nill {
        handle error
    } else {
        let data = result.data // This will be the whatever type you specified in NetworkResult<Type> above
        // handle the result here
    }
}

*/

import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

struct NetworkResult<Out> {
    let request: NSURLRequest?
    let response: NSHTTPURLResponse?
    let data: Out?
    let error: NSError?
}

protocol NetworkTask {
    func suspend()
    func resume()
    func cancel()
}

extension Request: NetworkTask {
}

protocol AuthorizationHeaderProvider {
    func authorizationHeader() -> String
}

class NetworkManager {

    var authorizationHeaderProvider: AuthorizationHeaderProvider?
    
    init(authorizationHeaderProvider: AuthorizationHeaderProvider? = nil) {
        self.authorizationHeaderProvider = authorizationHeaderProvider
    }
    
    func getWithURL<Out>(url: String, parameters: [String: AnyObject]? = nil, requiresAuthorization: Bool = true, handler: (NetworkResult<Out>) -> ()) -> NetworkTask {
        return request(method: .GET, url: url, parameters: parameters, requiresAuthorization: requiresAuthorization, handler: handler)
    }
    
    func postWithURL<Out>(url: String, parameters: [String: AnyObject], requiresAuthorization: Bool = true, handler: (NetworkResult<Out>) -> ()) -> NetworkTask {
        return request(method: .POST, url: url, parameters: parameters, requiresAuthorization: requiresAuthorization, handler: handler)
    }
    
    func request<Out>(#method: HTTPMethod, url: String, parameters: [String: AnyObject]? = nil, requiresAuthorization: Bool = true, handler: (NetworkResult<Out>) -> ()) -> NetworkTask {
        var encoding = ParameterEncoding.JSON
        if method == .GET {
            encoding = .URL
        }

        var request: Request
        if requiresAuthorization {
            let authHeader = authorizationHeaderProvider?.authorizationHeader() ?? ""
            let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
            mutableURLRequest.HTTPMethod = method.rawValue
            mutableURLRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            request = Manager.sharedInstance.request(encoding.encode(mutableURLRequest, parameters: parameters).0)
        } else {
            request = Manager.sharedInstance.request(Method(rawValue: method.rawValue)!, url, parameters: parameters, encoding: encoding)
        }

        if Out.self is NSData.Type {
            request.response() {
                (req: NSURLRequest?, res: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                if let theError = error {
                    let result = NetworkResult<Out>(request: req, response: res, data: nil, error: theError)
                    handler(result)
                } else {
                    let theData = data as! Out
                    let result = NetworkResult(request: req, response: res, data: theData, error: nil)
                    handler(result)
                }
            }
        } else if Out.self is NSString.Type || Out.self is NSNumber.Type || Out.self is NSNull.Type || Out.self is NSArray.Type || Out.self is NSDictionary.Type {
            request.responseJSON() {
                (req: NSURLRequest?, res: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                if let theError = error {
                    let result = NetworkResult<Out>(request: req, response: res, data: nil, error: theError)
                    handler(result)
                } else {
                    let theData = data as! Out
                    let result = NetworkResult(request: req, response: res, data: theData, error: nil)
                    handler(result)
                }
            }
        } else {
            assert(false, "can't convert the data to type \(Out.self). It's not supported.")
            fatalError("can't convert the data to type \(Out.self). It's not supported.")
        }
        return request
    }
}