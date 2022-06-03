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

    enum CourseUpgradeMode {
        case silent
        case normal
    }
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & NetworkManagerProvider & ReachabilityProvider & OEXInterfaceProvider
    typealias UpgradeCompletionHandler = (CourseUpgradeState) -> Void
    
    private var environment: Environment? = nil
    private var completion: UpgradeCompletionHandler?
    private(set) var course: OEXCourse?
    private var basketID: Int = 0
    private var courseSku: String = ""
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
                if error != .verifyReceiptError && upgradeMode != .silent {
                    CourseUpgradeHelper.shared.removeIAPSKUFromKeychain(courseSku)
                }
                break
            default:
                break
            }

            completion?(state)
        }
    }

    private(set) var upgradeMode: CourseUpgradeMode = .normal

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
                return Strings.CourseUpgrade.FailureAlert.courseNotFullfilled
            case .alreadyPurchased:
                return Strings.CourseUpgrade.FailureAlert.courseAlreadyPaid
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

    init(for course: OEXCourse, environment: Environment) {
        self.course = course
        self.environment = environment
        super.init()
    }
    
    func upgradeCourse(with upgradeMode: CourseUpgradeMode = .normal ,completion: UpgradeCompletionHandler?) {
        self.completion = completion
        self.upgradeMode = upgradeMode
        state = .initial
        
        guard let course = self.course,
              let coursePurchaseSku = UpgradeSKUManager.shared.courseSku(for: course) else {
                  state = .error(type: .generalError, error: error(message: "course sku is missing"))
                  return
              }
        
        courseSku = coursePurchaseSku

        PaymentManager.shared.alreadyPurchased(courseSku) { [weak self] success in
            if success ==  false {
                self?.proceedUpgrade(for: coursePurchaseSku)
            }
            else {
                let unfinishedSKUs = CourseUpgradeHelper.shared.savedUnfinishedIAPSKUsForCurrentUser() ?? []
                if unfinishedSKUs.contains(coursePurchaseSku) {
                    self?.proceedUpgrade(for: coursePurchaseSku)
                }
                else {
                    self?.state = .error(type: .alreadyPurchased, error: self?.error(message: "course is already purchased on this device"))
                }
            }
        }
    }

    private func proceedUpgrade(for courseSKU: String) {
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
                if self?.upgradeMode == .silent {
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
                PaymentManager.shared.markPurchaseComplete(self?.courseSku ?? "", type: (self?.upgradeMode == .silent) ? .transction : .purchase)
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

    private func error(message: String) -> NSError {
        return NSError(domain:"edx.app.courseupgrade", code: 1010, userInfo: [NSLocalizedDescriptionKey: JSON(["error": message])])
    }
}
