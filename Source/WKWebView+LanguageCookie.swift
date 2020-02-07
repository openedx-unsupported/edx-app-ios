//
//  WKWebView+LanguageCookie.swift
//  edX
//
//  Created by MuhammadUmer on 31/01/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

let SelectedLanguageCookieValue = "SelectedLanguageCookieValue"

extension WKWebView {
    private var languageCookieName: String {
        return "prod-edx-language-preference"
    }
    
    private var defaultLanguage: String {
        guard let deviceLanguage = NSLocale.current.languageCode else { return "en" }
        
        let preferredLocalizations = Bundle.main.preferredLocalizations
        
        for (index, language) in preferredLocalizations.enumerated() {
            if language.contains(find: deviceLanguage) {
                return preferredLocalizations[index]
            }
        }
        
        return "en"
    }
    
    private var storedLanguageCookieValue: String {
        set {
            UserDefaults.standard.set(newValue, forKey: SelectedLanguageCookieValue)
            UserDefaults.standard.synchronize()
        }
        get {
            return UserDefaults.standard.value(forKey: SelectedLanguageCookieValue) as? String ?? ""
        }
    }
    
    func loadRequest(_ request: URLRequest) {
        var request = request
        if #available(iOS 11.0, *) {
            guard let domain = request.url?.rootDomain,
                let languageCookie = HTTPCookie(properties: [
                    .domain: ".\(domain)",
                    .path: "/",
                    .name: languageCookieName,
                    .value: defaultLanguage,
                    .expires: NSDate(timeIntervalSinceNow: 3600000)
                ])
                else {
                    load(request)
                    return
            }
            
            getCookie(with: languageCookieName) { [weak self]  cookie in
                if let weakSelf = self {
                    if cookie == nil || weakSelf.storedLanguageCookieValue != weakSelf.defaultLanguage {
                        weakSelf.configuration.websiteDataStore.httpCookieStore.setCookie(languageCookie) {
                            weakSelf.storedLanguageCookieValue = weakSelf.defaultLanguage
                            weakSelf.load(request)
                            return
                        }
                    }
                }
            }
        } else {
            request.addValue("\(languageCookieName)=\(defaultLanguage))", forHTTPHeaderField: "Cookie")
        }
        load(request)
    }
}

@available(iOS 11.0, *)
extension WKWebView {
    private var httpCookieStore: WKHTTPCookieStore  { return WKWebsiteDataStore.default().httpCookieStore }
    
    func getCookie(with name: String, completion: @escaping (HTTPCookie?)-> ()) {
        httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if cookie.name.contains(name) {
                    completion(cookie)
                }
            }
        }
        completion(nil)
    }
}

extension URL {
    var rootDomain: String? {
        guard let hostName = host else { return nil }
        
        let components = hostName.components(separatedBy: ".")
        if components.count > 2 {
            return components.suffix(2).joined(separator: ".")
        } else {
            return hostName
        }
    }
}
