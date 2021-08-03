//
//  CourseUpgradeHandler.swift
//  edX
//
//  Created by Saeed Bashir on 8/16/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

class CourseUpgradeHandler: NSObject {

    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & NetworkManagerProvider & ReachabilityProvider
    typealias UpgradeCompletionHandler = ((success: Bool, error: PurchaseError?)) -> Void

    private var environment: Environment? = nil
    private var completion: UpgradeCompletionHandler?
    private var course: OEXCourse?
    private var basketID: Int = 0

    static let shared = CourseUpgradeHandler()

    func upgradeCourse(_ course: OEXCourse, environment: Environment?, completion: UpgradeCompletionHandler?) {
        self.completion = completion
        self.environment = environment
        self.course = course

        addToBasket { [weak self] orderBasket in
            if let basketID = orderBasket?.basketID {
                self?.basketID = basketID
                self?.checkout()
            }
        }
        
    }

    private func addToBasket(completion: @escaping (OrderBasket?) -> ()) {
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.basketAPI(with: "org.edx.mobile.integrationtest")
        environment?.networkManager.taskForRequest(base: baseURL, request) { response in
            if response.error == nil {
                completion(response.data)
            }
        }
    }
    
    private func checkout() {
        // Checkout API
        // Perform the inapp purchase on success
        guard basketID > 0 else {
            return
        }
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.checkoutAPI(basketID: basketID)
        environment?.networkManager.taskForRequest(base: baseURL, request) { [weak self] response in
            if response.error == nil {
                self?.makePayment()
            }
        }
    }

    private func makePayment() {
        PaymentManager.shared.purchaseProduct(productID) { [weak self] (success: Bool, receipt: String?, error: PurchaseError?) in
            if let receipt = receipt, success {
                self?.executeUpgrade(receipt)
            }
            else {
                // checkout error
            }
        }
    }

    private func executeUpgrade(_ receipt: String) {
        // Execute API, pass the payment receipt to complete the course upgrade
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.executeAPI(basketID: basketID, productID: productID, receipt: receipt)

        environment?.networkManager.taskForRequest(base: baseURL, request, handler: { [weak self] response in
            if response.error == nil {
                PaymentManager.shared.markPurchaseComplete(self?.course?.course_id ?? "", type: .purchase)
                self?.completion?((true, nil))
            }
        })
    }
}
