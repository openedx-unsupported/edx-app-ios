//
//  OEXRegistrationViewController+Swift.swift
//  edX
//
//  Created by Danial Zahid on 9/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension OEXRegistrationViewController {
    
    @objc func getRegistrationFormDescription(success: @escaping (_ response: OEXRegistrationDescription) -> ()) {
        let networkManager = environment.networkManager
        let apiVersion = environment.config.apiUrlVersionConfig.registration
        let networkRequest = RegistrationFormAPI.registrationFormRequest(version: apiVersion)
        
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
    
    private func error(with name: String, _ validationDecisions: ValidationDecisions) -> String? {
        guard let value = ValidationDecisions.Keys(rawValue: name),
            ValidationDecisions.Keys.allCases.contains(value),
            let errorValue = validationDecisions.value(forKeyPath: value.rawValue) as? String,
            !errorValue.isEmpty else { return nil }
        return errorValue
    }
    
    private func handle(_ error: NSError) {
        view.isUserInteractionEnabled = true
        if error.code == -1001 || error.code == -1003 {
            UIAlertController().showAlert(withTitle: Strings.timeoutAlertTitle, message: Strings.timeoutCheckInternetConnection, onViewController: self)
        } else {
            UIAlertController().showAlert(withTitle: Strings.Accessibility.errorText, message: error.localizedDescription, onViewController: self)
        }
    }
    
    @objc func validateRegistrationForm(parameters: [String: String]) {
        showProgress(true)
        
        let networkManager = environment.networkManager
        let networkRequest = RegistrationFormAPI.registrationFormValidationRequest(parameters: parameters)
        
        networkManager.taskForRequest(networkRequest) { [weak self] result in
            if let error = result.error {
                self?.showProgress(false)
                self?.handle(error)
                return
            }
            guard let owner = self,
                let validationDecisions = result.data?.validationDecisions else {
                    self?.showProgress(false)
                    self?.register(withParameters: parameters)
                    return
            }
            
            var firstControllerWithError: OEXRegistrationFieldController?
            
            for case let controller as OEXRegistrationFieldController in owner.fieldControllers {
                controller.accessibleInputField?.resignFirstResponder()
                
                if let error = owner.error(with: controller.field.name, validationDecisions) {
                    controller.handleError(error)
                    if firstControllerWithError == nil {
                        firstControllerWithError = controller
                    }
                }
            }
            
            owner.showProgress(false)
            
            if firstControllerWithError == nil {
                owner.register(withParameters: parameters)
            } else {
                owner.refreshFormFields()
                UIAlertController().showAlert(withTitle: Strings.registrationErrorAlertTitle, message: Strings.registrationErrorAlertMessage, cancelButtonTitle: Strings.ok, onViewController: owner) { _, _, _ in
                    firstControllerWithError?.accessibleInputField?.becomeFirstResponder()
                }
            }
        }
    }
    
    @objc func register(withParameters parameter:[String:String]) {
        showProgress(true)
        let infoDict: [String: String] = [OEXAnalyticsKeyProvider: externalProvider?.backendName ?? ""]
        environment.analytics.trackEvent(OEXAnalytics.registerEvent(name: AnalyticsEventName.UserRegistrationClick.rawValue, displayName: AnalyticsDisplayName.CreateAccount.rawValue), forComponent: nil, withInfo: infoDict)
        let apiVersion = environment.config.apiUrlVersionConfig.registration
        OEXAuthentication.registerUser(withApiVersion: apiVersion, paramaters: parameter) { [weak self] (data: Data?, response: HTTPURLResponse?, error: Error?) in
            if let owner = self  {
                if let data = data, error == nil {
                    let completion: ((_: Data?, _: HTTPURLResponse?, _: Error?) -> Void) = {(_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void in
                        if response?.statusCode == OEXHTTPStatusCode.code200OK.rawValue {
                            owner.environment.analytics.trackEvent(OEXAnalytics.registerEvent(name: AnalyticsEventName.UserRegistrationSuccess.rawValue, displayName: AnalyticsDisplayName.RegistrationSuccess.rawValue), forComponent: nil, withInfo: infoDict)
                            owner.delegate?.registrationViewControllerDidRegister(owner, completion: nil)
                        }
                        else if let error = error as NSError?, error.oex_isNoInternetConnectionError {
                            owner.showNoNetworkError()
                        }
                        owner.showProgress(false)
                    }
                    if (response?.statusCode == OEXHTTPStatusCode.code200OK.rawValue) {
                        if let externalProvider = self?.externalProvider {
                            owner.attemptExternalLogin(with: externalProvider, token: owner.externalAccessToken, completion: completion)
                        }
                        else {
                            let username = parameter["username"] ?? ""
                            let password = parameter["password"] ?? ""
                            OEXAuthentication.requestToken(withUser: username, password: password, completionHandler: completion)
                        }
                    }
                    else {
                        var controllers : [String: Any] = [:]
                        for controller in owner.fieldControllers {
                            let controller = controller as? OEXRegistrationFieldController
                            controllers.setSafeObject(controller, forKey: controller?.field.name ?? "")
                            controller?.handleError("")
                        }
                        
                        do {
                            let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as AnyObject
                            if dictionary is Dictionary<AnyHashable, Any> {
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
                            }
                        } catch let error as NSError {
                            Logger.logError("Registration", "Failed to load: \(error.localizedDescription)")
                        }
                        owner.showProgress(false)
                        owner.refreshFormFields()
                    }
                }
                else {
                    if let error = error as NSError?, error.oex_isNoInternetConnectionError {
                        owner.showNoNetworkError()
                    }
                    owner.showProgress(false)
                }
            }
        }
    }
    
    //Testing only
    public var t_loaded : OEXStream<()> {
        return (self.stream as! OEXStream<OEXRegistrationDescription>).map {_ in () }
    }

}
