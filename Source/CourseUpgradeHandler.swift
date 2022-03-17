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
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & NetworkManagerProvider & ReachabilityProvider & OEXInterfaceProvider
    typealias UpgradeCompletionHandler = (CourseUpgradeState) -> Void
    
    private var environment: Environment? = nil
    private var completion: UpgradeCompletionHandler?
    private var course: OEXCourse?
    private var basketID: Int = 0
    private var courseSku: String = ""
    private var state: CourseUpgradeState = .initial {
        didSet {
            completion?(state)
        }
    }

    var formattedError: String {
        if case .error(let type, let error) = state {
            guard let error = error as NSError? else { return "unhandledError" }
            
            if case .paymentError = type {
                return "\(type.errorString)-\(error.code)-\(error.localizedDescription)"
            }
            
            if let errorResponse = error.userInfo.values.first,
               let json = errorResponse as? JSON,
               let errorMessage = json.dictionary?.values.first {
                return "\(type.errorString)-\(error.code)-\(errorMessage)"
            }
        }
        return "unhandledError"
    }
    
    static let shared = CourseUpgradeHandler()
    
    func upgradeCourse(_ course: OEXCourse, environment: Environment, completion: UpgradeCompletionHandler?) {
        self.completion = completion
        self.environment = environment
        self.course = course
        
        state = .initial
        
        guard let coursePurchaseSku = UpgradeSKUManager.shared.courseSku(for: course) else {
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
    
    func upgradeCourse(_ courseID: String, environment: Environment, completion: UpgradeCompletionHandler?) {
        guard let course = environment.interface?.enrollmentForCourse(withID: courseID)?.course else {
            state = .error(type: .generalError, error: nil)
            return
        }
        
        upgradeCourse(course, environment: environment, completion: completion)
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
                self?.makePayment()
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
                PaymentManager.shared.markPurchaseComplete(self?.course?.course_id ?? "", type: .purchase)
                self?.state = .complete
            } else {
                self?.state = .error(type: .verifyReceiptError, error: response.error)
            }
        }
    }

    private func error(message: String) -> NSError {
        return NSError(domain:"edx.app.courseupgrade", code: 1010, userInfo: [NSLocalizedDescriptionKey: JSON(["error": message])])
    }
}
