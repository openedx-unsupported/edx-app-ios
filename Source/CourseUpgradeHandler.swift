//
//  CourseUpgradeHandler.swift
//  edX
//
//  Created by Saeed Bashir on 8/16/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

class CourseUpgradeHandler: NSObject {

    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & NetworkManagerProvider & ReachabilityProvider & OEXInterfaceProvider
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
            else {
                completion?((false, .basketError))
            }
        }
    }

    func upgradeCourse(_ courseID: String, environment: Environment?, completion: UpgradeCompletionHandler?) {
        guard let course = environment?.interface?.enrollmentForCourse(withID: courseID)?.course else {
            completion?((false, .generalError))
            return
        }

        upgradeCourse(course, environment: environment, completion: completion)
    }

    private func addToBasket(completion: @escaping (OrderBasket?) -> ()) {
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.basketAPI(with: TestInAppPurchaseID)
        environment?.networkManager.taskForRequest(base: baseURL, request) { response in
            completion(response.data)
        }
    }
    
    private func checkout() {
        // Checkout API
        // Perform the inapp purchase on success
        guard basketID > 0 else {
            completion?((false, .checkoutError))
            return
        }
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.checkoutAPI(basketID: basketID)
        environment?.networkManager.taskForRequest(base: baseURL, request) { [weak self] response in
            if response.error == nil {
                self?.makePayment()
            }
            else {
                self?.completion?((false, .checkoutError))
            }
        }
    }

    private func makePayment() {
        PaymentManager.shared.purchaseProduct(TestInAppPurchaseID) { [weak self] (success: Bool, receipt: String?, error: PurchaseError?) in
            if let receipt = receipt, success {
                self?.executeUpgrade(receipt)
            }
            else {
                self?.completion?((false, error))
            }
        }
    }

    private func executeUpgrade(_ receipt: String) {
        // Execute API, pass the payment receipt to complete the course upgrade
        let baseURL = CourseUpgradeAPI.baseURL
        let request = CourseUpgradeAPI.executeAPI(basketID: basketID, productID: TestInAppPurchaseID, receipt: receipt)

        environment?.networkManager.taskForRequest(base: baseURL, request, handler: { [weak self] response in
            if response.error == nil {
                PaymentManager.shared.markPurchaseComplete(self?.course?.course_id ?? "", type: .purchase)
                self?.completion?((true, nil))
            }
            else {
                self?.completion?((false, .verifyReceiptError))
            }
        })
    }
}
