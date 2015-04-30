/**
Copyright (c) 2015 Qualcomm Education, Inc.
All rights reserved.


Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

* Neither the name of Qualcomm Education, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

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