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
        case basket
        case checkout
        case payment
        case verify
        case complete
        case error(type: PurchaseError, error: Error?)
    }

    enum CourseUpgradeMode: String {
        case silent = "silent"
        case userInitiated = "user_initiated"
        case restore = "restore"
    }
    
    typealias Environment = NetworkManagerProvider & OEXConfigProvider
    typealias UpgradeCompletionHandler = (CourseUpgradeState) -> Void
    
    private var environment: Environment? = nil
    private var completion: UpgradeCompletionHandler?
    private(set) var course: OEXCourse?
    private var basketID: Int = 0
    private var courseSku: String = ""
    private(set) var upgradeMode: CourseUpgradeMode = .userInitiated
    private(set) var price: NSDecimalNumber?
    private(set) var currencyCode: String?

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
                if error != .verifyReceiptError && upgradeMode == .userInitiated {
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
    
    func upgradeCourse(with upgradeMode: CourseUpgradeMode = .userInitiated, price: NSDecimalNumber?, currencyCode: String?, completion: UpgradeCompletionHandler?) {
        self.completion = completion
        self.upgradeMode = upgradeMode
        self.price = price
        self.currencyCode = currencyCode
        
        guard let course = self.course,
              let coursePurchaseSku = course.sku else {
            state = .error(type: .generalError, error: error(message: "course sku is missing"))
            return
        }
        state = .initial
        courseSku = coursePurchaseSku
        proceedWithUpgrade()
    }
    
    private func proceedWithUpgrade() {
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
                if self?.upgradeMode != .userInitiated {
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
        let request = CourseUpgradeAPI.executeAPI(basketID: basketID, productID: courseSku, price: price ?? 0, currencyCode: currencyCode ?? "", receipt: receipt)
        
        environment?.networkManager.taskForRequest(base: baseURL, request) { [weak self] response in
            if response.error == nil {
                PaymentManager.shared.markPurchaseComplete(self?.courseSku ?? "", type: (self?.upgradeMode == .userInitiated) ? .purchase : .transction)
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
            else if let errorMessage = error.userInfo[NSLocalizedDescriptionKey] as? String {
                return errorMessage
            }

            return "\(type.errorString)-\(error.code)-\(unhandledError)"
        }
        return unhandledError
    }

    fileprivate func error(message: String) -> NSError {
        return NSError(domain:"edx.app.courseupgrade", code: 1010, userInfo: [NSLocalizedDescriptionKey: JSON(["error": message])])
    }
}
