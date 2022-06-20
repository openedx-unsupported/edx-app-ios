//
//  WebviewSessionManager.swift
//  edX
//
//  Created by Saeed Bashir on 1/6/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

let WebviewCookiesCreatedNotification = "CookiesCreatedNotification"

enum WebviewCookiesManagerState {
    case none, creating, sync, created, failed
}

// A class that will manage the session and other relevant cookies for AuthenticatedWebViewController
// This class will be responsbile for making the /oauth2/login/ and manage session cookies
class WebviewCookiesManager: NSObject {

    // We'll assume that cookies are valid for at least one hour after that
    // we'll refresh the cookies, the cookies expiration is also being handled in the response of webview loading
    private let refreshInterval: Double = 60 * 60
    private var authSessionCookieExpiration: Double = -1
    private(set) var cookiesState: WebviewCookiesManagerState = .none
    static let shared = WebviewCookiesManager()

    typealias Environment = NetworkManagerProvider
    private var environment: Environment?


    var cookiesExpired: Bool {
        return authSessionCookieExpiration < Date().timeIntervalSince1970
    }

    private override init() {
        super.init()

        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, observer, _) in
            observer.clearCookies()
        }
    }

    public func createOrUpdateCookies(environment: Environment) {
        self.environment = environment
        clearCookies()
        cookiesState = .creating

        environment.networkManager.taskForRequest(loginAPI()) { [weak self] result in
            self?.updateSessionState(state: result.error == nil ? .sync : .failed)
        }
    }

    func clearCookies() {
        authSessionCookieExpiration = -1
        cookiesState = .none
        let storage = HTTPCookieStorage.shared
        let cookies = storage.cookies
        for cookie in cookies ?? [] {
            storage.deleteCookie(cookie)
        }
    }

    private func parseAndSetCookies(response: HTTPURLResponse) {
        guard let fields = response.allHeaderFields as? [String : String],
              let url = OEXConfig.shared().apiHostURL()
        else { return }

        let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
        HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
    }

    func updateSessionState(state: WebviewCookiesManagerState) {
        cookiesState = state
        switch state {
        case .sync:
            authSessionCookieExpiration = Date().addingTimeInterval(refreshInterval).timeIntervalSince1970
            postCookiesSetNotification(status: true)
            break
        case .created:
            break
        default:
            authSessionCookieExpiration = -1
            postCookiesSetNotification(status: false)
            clearCookies()  
            break
        }
    }

    private func postCookiesSetNotification(status: Bool) {
        NotificationCenter.default.post(name: NSNotification.Name(WebviewCookiesCreatedNotification), object: status)
    }

    private func loginAPI() -> NetworkRequest<()> {
        let path = "/oauth2/login/"

        return NetworkRequest(
            method: .POST,
            path: path,
            requiresAuth: true,
            deserializer: .noContent(cookiesDeserializer))
    }

    private func cookiesDeserializer(response: HTTPURLResponse) -> Result<()> {
        guard response.httpStatusCode.is2xx else {
            return Failure(e: NSError(domain: "LoginApiErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "unable to get cookies"]))
        }

        parseAndSetCookies(response: response)

        return Success(v: ())
    }
}
