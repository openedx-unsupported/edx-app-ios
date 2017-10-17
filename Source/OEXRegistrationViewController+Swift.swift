//
//  OEXRegistrationViewController+Swift.swift
//  edX
//
//  Created by Danial Zahid on 9/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension OEXRegistrationViewController {
    
    func getRegistrationFormDescription(success: @escaping (_ response: OEXRegistrationDescription) -> ()) {
        let networkManager = self.environment.networkManager
        let networkRequest = RegistrationFormAPI.registrationFormRequest()
        
        self.stream = networkManager.streamForRequest(networkRequest)
        (self.stream as! OEXStream<OEXRegistrationDescription>).listen(self) {[weak self] (result) in
            if let data = result.value {
                self?.loadController.state = .Loaded
                success(data)
            }
            else{
                self?.loadController.state = LoadState.failed(error: result.error)
            }
        }
    }
    
    func register(withParameters parameter:[String:String]) {
        self.showProgress(true)
        let infoDict :[String: String] = [OEXAnalyticsKeyProvider: self.externalProvider?.backendName ?? ""]
        self.environment.analytics.trackEvent(OEXAnalytics.registerEvent(name: AnalyticsEventName.UserRegistrationClick.rawValue, displayName: AnalyticsDisplayName.CreateAccount.rawValue), forComponent: nil, withInfo: infoDict)
        OEXAuthentication.registerUser(withParameters: parameter) { (data: Data?, response: HTTPURLResponse?, error: Error?) in
            if let data = data  {
                let dictionary: AnyObject = JSONSerialization.oex_JSONObject(with: data, error: nil) as AnyObject
                let completion: ((_: Data?, _: HTTPURLResponse?, _: Error?) -> Void) = {[weak self] (_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void in
                        if let owner = self {
                            if response?.statusCode == OEXHTTPStatusCode.code200OK.rawValue {
                                owner.environment.analytics.trackEvent(OEXAnalytics.registerEvent(name: AnalyticsEventName.UserRegistrationSuccess.rawValue, displayName: AnalyticsDisplayName.RegistrationSuccess.rawValue), forComponent: nil, withInfo: infoDict)
                                owner.delegate?.registrationViewControllerDidRegister(owner, completion: { _ in })
                            }
                            else if let error = error as NSError?, error.oex_isNoInternetConnectionError {
                                owner.showNoNetworkError()
                            }
                            owner.showProgress(false)
                        }
                }
                if (response?.statusCode == OEXHTTPStatusCode.code200OK.rawValue) {
                    if let externalProvider = self.externalProvider {
                        self.attemptExternalLogin(with: externalProvider, token: self.externalAccessToken, completion: completion)
                    }
                    else {
                        let username = parameter["username"] ?? ""
                        let password = parameter["password"] ?? ""
                        OEXAuthentication.requestToken(withUser: username, password: password, completionHandler: completion)
                    }
                }
                else {
                    var controllers : [String: Any] = [:]
                    for controller in self.fieldControllers {
                        let controller = controller as? OEXRegistrationFieldController
                        controllers.setSafeObject(controller, forKey: controller?.field.name ?? "")
                        controller?.handleError("")
                    }
                    dictionary.enumerateKeysAndObjects({ (key, value, stop) in
                        let key = key as? String ?? ""
                        weak var controller: OEXRegistrationFieldController? = controllers[key] as? OEXRegistrationFieldController
                        if let array = value as? NSArray {
                          let errorStrings = array.oex_map({ (info) -> Any in
                                if let info = info as? [AnyHashable: Any] {
                                    return OEXRegistrationFieldError(dictionary: info).userMessage
                                }
                            return  OEXRegistrationFieldError().userMessage

                            })
                           let errors = (errorStrings as NSArray).componentsJoined(by: " ")
                            controller?.handleError(errors)
                        }
                    })
                    self.showProgress(false)
                    self.refreshFormFields()
                }
            }
            else {
                if let error = error as NSError?, error.oex_isNoInternetConnectionError {
                    self.showNoNetworkError()
                }
                self.showProgress(false)
            }
        }
    }
    
    //Testing only
    public var t_loaded : OEXStream<()> {
        return (self.stream as! OEXStream<OEXRegistrationDescription>).map {_ in () }
    }

}
