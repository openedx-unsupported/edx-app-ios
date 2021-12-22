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
        case error(PurchaseError)
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
    
    static let shared = CourseUpgradeHandler()
    
    func upgradeCourse(_ course: OEXCourse, environment: Environment, completion: UpgradeCompletionHandler?) {
        self.completion = completion
        self.environment = environment
        self.course = course
        
        state = .initial
        
        if let coursePurchaseSku = UpgradeSKUManager.shared.courseSku(for: course) {
            courseSku = coursePurchaseSku
        } else {
            state = .error(.generalError)
            return
        }
        
        addToBasket { [weak self] orderBasket in
            if let basketID = orderBasket?.basketID {
                self?.basketID = basketID
                self?.checkout()
            } else {
                self?.state = .error(.basketError)
            }
        }
    }
    
    func upgradeCourse(_ courseID: String, environment: Environment, completion: UpgradeCompletionHandler?) {
        guard let course = environment.interface?.enrollmentForCourse(withID: courseID)?.course else {
            state = .error(.generalError)
            return
        }
        
        upgradeCourse(course, environment: environment, completion: completion)
    }
    
    private func addToBasket(completion: @escaping (OrderBasket?) -> ()) {
        state = .basket
        
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.basketAPI(with: courseSku)
        
        environment?.networkManager.taskForRequest(base: baseURL, request) { response in
            completion(response.data)
        }
    }
    
    private func checkout() {
        // Checkout API
        // Perform the inapp purchase on success
        guard basketID > 0 else {
            state = .error(.checkoutError)
            return
        }
        
        state = .checkout
        
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.checkoutAPI(basketID: basketID)
        
        environment?.networkManager.taskForRequest(base: baseURL, request) { [weak self] response in
            if response.error == nil {
                self?.makePayment()
            } else {
                self?.state = .error(.checkoutError)
            }
        }
    }
    
    private func makePayment() {
        state = .payment
        PaymentManager.shared.purchaseProduct(courseSku) { [weak self] (success: Bool, receipt: String?, error: PurchaseError?) in
            if let receipt = receipt, success {
                self?.verifyPayment(receipt)
            } else {
                self?.state = .error(error ?? .paymentError)
            }
        }
    }
    
    private func verifyPayment(_ receipt: String) {
        state = .verify
        
        // Execute API, pass the payment receipt to complete the course upgrade
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.executeAPI(basketID: basketID, productID: courseSku, receipt: receipt)
        
        environment?.networkManager.taskForRequest(base: baseURL, request){ [weak self] response in
            if response.error == nil {
                PaymentManager.shared.markPurchaseComplete(self?.course?.course_id ?? "", type: .purchase)
                self?.state = .complete
            } else {
                self?.state = .error(.verifyReceiptError)
            }
        }
    }
}
