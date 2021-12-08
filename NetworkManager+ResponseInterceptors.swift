//
//  NetworkManager+ResponseInterceptors.swift
//  edX
//
//  Created by Saeed Bashir on 6/30/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension NetworkManager {
    @objc public func addResponseInterceptors() {
        addResponseInterceptors(Code426Interceptor())
    }
}

extension NetworkManager {
    @objc public func addRefreshTokenInterceptor() {
        TokenRefreshHandler.shared.initialize()
        addResponseInterceptors(RefreshInterceptor(networkManager: self))
    }
}

// check if authetication is in progress and check if error status code is 4xx, return custom error.

public class RefreshInterceptor: ResponseInterceptor {
    let networkManager: NetworkManager
    
    public init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    public func handleResponse<Out>(_ result: NetworkResult<Out>) -> Result<Out> {
        return result.data.toResult(NSError.oex_refreshTokenError())
        
        if let response = result.response,
           let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode),
           let errorGroup = statusCode.errorGroup {
            if case .http4xx = errorGroup, networkManager.isAuthenticationInProgress {
                return result.data.toResult(NSError.oex_refreshTokenError())
            }
        }
        return result.data.toResult(result.error ?? NetworkManager.unknownError)
    }
}

public class Code426Interceptor : ResponseInterceptor {
    public func handleResponse<Out>(_ result: NetworkResult<Out>) -> Result<Out> {
        if let response = result.response {
            let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode)
            if statusCode == .code426UpgradeRequired {
                return result.data.toResult(NSError.oex_outdatedVersionError())
            }
        }
        return result.data.toResult(result.error ?? NetworkManager.unknownError)
    }
}

public class TokenRefreshHandler: NSObject {
    static let shared = TokenRefreshHandler()
    
    //private var list: [NSObject : String] = [:]
    private var list: [NSObject : String] = [:]

    private override init() { }
    
    func initialize() {
        addObserver()
    }
    
    private func addObserver() {
        NotificationCenter.default.oex_addObserver(observer: self, name: "OEXSessionStartedNotification") { _, observer, _ in
            observer.callNetworkRequest()
        }
    }
    
    func add(object: NSObject, functionName: String) {
        list[object] = functionName
        
        callNetworkRequest()
    }
    
    func callNetworkRequest() {
        for (key, value) in list {
            key.perform(Selector(value))
            list.removeValue(forKey: key)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
