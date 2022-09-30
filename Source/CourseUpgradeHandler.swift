//
//  CourseUpgradeHandler.swift
//  edX
//
//  Created by Saeed Bashir on 8/16/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

class CourseUpgradeHandler: NSObject {
    
    enum CourseUpgradeState {
        case initial
        case sdn
        case basket
        case checkout
        case payment
        case verify
        case complete
        case error(type: PurchaseError, error: Error?)
    }

    enum CourseUpgradeMode {
        case silent
        case normal
        case restore
    }
    
    typealias Environment = NetworkManagerProvider & OEXConfigProvider
    typealias UpgradeCompletionHandler = (CourseUpgradeState) -> Void
    
    private var environment: Environment? = nil
    private var completion: UpgradeCompletionHandler?
    private(set) var course: OEXCourse?
    private var basketID: Int = 0
    private var courseSku: String = ""
    private(set) var upgradeMode: CourseUpgradeMode = .normal

    private(set) var state: CourseUpgradeState = .initial {
        didSet {
            switch state {
            case .basket:
                CourseUpgradeHelper.shared.saveIAPInKeychain(courseSku)
                break
            case .complete:
                CourseUpgradeHelper.shared.markIAPSKUCompleteInKeychain(courseSku)
                break
            case .error(let error, _):
                if error != .verifyReceiptError && upgradeMode == .normal {
                    CourseUpgradeHelper.shared.removeIAPSKUFromKeychain(courseSku)
                }
                break
            default:
                break
            }

            completion?(state)
        }
    }

    init(for course: OEXCourse, environment: Environment) {
        self.course = course
        self.environment = environment
        super.init()
    }
    
    func upgradeCourse(with upgradeMode: CourseUpgradeMode = .normal, completion: UpgradeCompletionHandler?) {
        self.completion = completion
        self.upgradeMode = upgradeMode
        
        state = .initial
        // Show SDN alert only for while doing the payment
        // Don't show in case of auto fullfilment on app reelaunch and restore
        if upgradeMode == .normal {
            state = .sdn
            showSDNprompt { [weak self] success in
                if success {
                    self?.proceedWithUpgrade()
                } else {
                    self?.state = .error(type: .sdnError, error: self?.error(message: "user does not allow sdn check"))
                }
            }
        }
        else {
            proceedWithUpgrade()
        }
    }
    
    private func showSDNprompt(completion: @escaping (Bool) -> ()) {
        guard let controller = UIApplication.shared.topMostController() else { return }
        
        let alert = UIAlertController().alert(withTitle: Strings.CourseUpgrade.Sdn.Prompt.title, message: Strings.CourseUpgrade.Sdn.Prompt.message(platformName: environment?.config.platformName() ?? ""), cancelButtonTitle: Strings.CourseUpgrade.Sdn.Prompt.confirm) { controller, _, buttonIndex in
            if buttonIndex == controller.cancelButtonIndex {
                completion(true)
            }
        }
        
        alert.setMessageAlignment(.left)
        
        alert.addButton(withTitle: Strings.CourseUpgrade.Sdn.Prompt.reject) { _ in
            completion(false)
        }
        
        controller.present(alert, animated: true)
    }
    
    private func proceedWithUpgrade() {
        guard let course = self.course,
              let coursePurchaseSku = course.sku else {
                  state = .error(type: .generalError, error: error(message: "course sku is missing"))
                  return
              }
        courseSku = coursePurchaseSku

        addToBasket { [weak self] (orderBasket, error) in
            if let basketID = orderBasket?.basketID {
                self?.basketID = basketID
                self?.checkout()
            } else {
                self?.state = .error(type: .basketError, error: error)
            }
        }
    }
    
    private func addToBasket(completion: @escaping (OrderBasket?, Error?) -> ()) {
        state = .basket

        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.basketAPI(with: courseSku)
        
        environment?.networkManager.taskForRequest(base: baseURL, request) { response in
            completion(response.data, response.error)
        }
    }
    
    private func checkout() {
        // Checkout API
        guard basketID > 0 else {
            state = .error(type: .checkoutError, error: error(message: "invalid basket id < zero"))
            return
        }
        
        state = .checkout
        
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.checkoutAPI(basketID: basketID)
        
        environment?.networkManager.taskForRequest(base: baseURL, request) { [weak self] response in
            if response.error == nil {
                if self?.upgradeMode != .normal {
                    self?.reverifyPayment()
                } else {
                    self?.makePayment()
                }
            } else {
                self?.state = .error(type: .checkoutError, error: response.error)
            }
        }
    }
    
    private func makePayment() {
        state = .payment
        PaymentManager.shared.purchaseProduct(courseSku) { [weak self] success, receipt, error in
            if let receipt = receipt, success {
                self?.verifyPayment(receipt)
            } else {
                self?.state = .error(type: (error?.type ?? .paymentError), error: error?.error)
            }
        }
    }
    
    private func verifyPayment(_ receipt: String) {
        state = .verify
        
        // Execute API, pass the payment receipt to complete the course upgrade
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.executeAPI(basketID: basketID, productID: courseSku, receipt: receipt)
        
        environment?.networkManager.taskForRequest(base: baseURL, request) { [weak self] response in
            if response.error == nil {
                PaymentManager.shared.markPurchaseComplete(self?.courseSku ?? "", type: (self?.upgradeMode == .normal) ? .purchase : .transction)
                self?.state = .complete
            } else {
                self?.state = .error(type: .verifyReceiptError, error: response.error)
            }
        }
    }

    // Give an option of retry to learner
    func reverifyPayment() {
        PaymentManager.shared.purchaseReceipt { [weak self] success, receipt, error in
            if let receipt = receipt, success {
                self?.verifyPayment(receipt)
            } else {
                self?.state = .error(type: (error?.type ?? .receiptNotAvailable), error: error?.error)
            }
        }
    }
}

extension CourseUpgradeHandler {
    // IAP error messages
    var errorMessage: String {
        if case .error (let type, let error) = state {
            guard let error = error as NSError? else { return Strings.CourseUpgrade.FailureAlert.generalErrorMessage }
            switch type {
            case .basketError:
                return basketErrorMessage(for: error)
            case .checkoutError:
                return checkoutErrorMessage(for: error)
            case .paymentError:
                return Strings.CourseUpgrade.FailureAlert.paymentNotProcessed
            case .verifyReceiptError:
                return executeErrorMessage(for: error)
            default:
                return Strings.CourseUpgrade.FailureAlert.paymentNotProcessed
            }
        }
        return Strings.CourseUpgrade.FailureAlert.generalErrorMessage
    }

    private func basketErrorMessage(for error: NSError) -> String {
        switch error.code {
        case 400:
            return Strings.CourseUpgrade.FailureAlert.courseNotFount
        case 403:
            return Strings.CourseUpgrade.FailureAlert.authenticationErrorMessage
        case 406:
            return Strings.CourseUpgrade.FailureAlert.courseAlreadyPaid
        default:
            return Strings.CourseUpgrade.FailureAlert.paymentNotProcessed
        }
    }

    private func checkoutErrorMessage(for error: NSError) -> String {
        switch error.code {
        case 403:
            return Strings.CourseUpgrade.FailureAlert.authenticationErrorMessage
        default:
            return Strings.CourseUpgrade.FailureAlert.paymentNotProcessed
        }
    }

    private func executeErrorMessage(for error: NSError) -> String {
        switch error.code {
        case 409:
            return Strings.CourseUpgrade.FailureAlert.courseAlreadyPaid
        default:
            return Strings.CourseUpgrade.FailureAlert.courseNotFullfilled
        }
    }

    var formattedError: String {
        let unhandledError = "unhandledError"
        if case .error(let type, let error) = state {
            guard let error = error as NSError? else { return unhandledError }

            if case .paymentError = type {
                return "\(type.errorString)-\(error.code)-\(error.localizedDescription)"
            }

            if let errorResponse = error.userInfo.values.first,
               let json = errorResponse as? JSON,
               let errorMessage = json.dictionary?.values.first {
                return "\(type.errorString)-\(error.code)-\(errorMessage)"
            }

            return "\(type.errorString)-\(error.code)-\(unhandledError)"
        }
        return unhandledError
    }

    fileprivate func error(message: String) -> NSError {
        return NSError(domain:"edx.app.courseupgrade", code: 1010, userInfo: [NSLocalizedDescriptionKey: JSON(["error": message])])
    }
}
