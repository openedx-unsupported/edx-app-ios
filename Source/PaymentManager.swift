//
//  PaymentManager.swift
//  edX
//
//  Created by Muhammad Umer on 22/06/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
import SwiftyStoreKit

let TestInAppPurchaseID = "org.edx.mobile.integrationtest"
private let CourseUpgradeCompleteNotification: String = "CourseUpgradeCompleteNotification"


// In case of completeTransctions SDK returns SwiftyStoreKit.Purchase
// And on the in-app purchase SDK returns SwiftyStoreKit.PurchaseDetails
enum TransctionType: String {
    case transction
    case purchase
}

enum PurchaseError: String {
    case paymentsNotAvailebe // device isn't allowed to make payments
    case invalidUser // app user isn't available
    case paymentError // unable to purchase a product
    case receiptNotAvailable // unable to fetech inapp purchase receipt
    case basketError // basket API returns error
    case checkoutError // checkout API returns error
    case verifyReceiptError // verify receipt API returns error
    case generalError // general error
}

@objc class PaymentManager: NSObject {
    private typealias storeKit = SwiftyStoreKit
    @objc static let shared = PaymentManager()
    // Use this dictionary to keep track of inprocess transctions and allow only one transction at a time
    private var purchasess: [String: Any] = [:]

    typealias PurchaseCompletionHandler = ((success: Bool, receipt: String?, error: PurchaseError?)) -> Void
    var completion: PurchaseCompletionHandler?

    var isIAPInprocess:Bool {
        return purchasess.count > 0
    }

    var inprocessPurchases: [String: Any] {
        return purchasess
    }

    private override init() {

    }

    @objc func completeTransactions() {
        // save and check if purchase is already there
        storeKit.completeTransactions(atomically: false) { [weak self] purchases in // atomically = false
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        // self?.markPurchaseComplete(productID, type: .transction)
                        // SwiftyStoreKit.finishTransaction(purchase.transaction)
                        self?.purchasess[purchase.productId] =  purchase
                    }
                case .failed, .purchasing, .deferred:
                    // TODO: Will handle while implementing the final version
                    // At the momewnt don't have anything to add here
                    break // do nothing
                @unknown default:
                    break // do nothing
                }
            }
        }
    }

    func purchaseProduct(_ identifier: String, completion: PurchaseCompletionHandler?) {
        guard storeKit.canMakePayments else {
            if let controller = UIApplication.shared.topMostController() {
                UIAlertController().showAlert(withTitle: "Payment Error", message: "This device is not able or allowed to make payments", onViewController: controller)
            }
            completion?((false, receipt: nil, error: .paymentsNotAvailebe))
            return
        }

        guard let applicationUserName = OEXSession.shared()?.currentUser?.username else {
            completion?((false, receipt: nil, error: .invalidUser))
            return
        }
        self.completion = completion

        storeKit.purchaseProduct(identifier, atomically: false, applicationUsername: applicationUserName) { [weak self] result in
            switch result {
            case .success(let purchase):
                self?.purchasess[purchase.productId] = purchase
                self?.purchaseReceipt()
                break
            case .error(let error):
                completion?((false, receipt: nil, error: .paymentError))
                switch error.code {
                //TOD: handle the following cases according to the requirments
                case .unknown:
                    break
                case .clientInvalid:
                    break
                case .paymentCancelled:
                    break
                case .paymentInvalid:
                    break
                case .paymentNotAllowed:
                    break
                case .storeProductNotAvailable:
                    break
                case .cloudServicePermissionDenied:
                    break
                case .cloudServiceNetworkConnectionFailed:
                    break
                case .cloudServiceRevoked:
                    break
                default: print((error as NSError).localizedDescription)
                }
            }
        }
    }

    func productPrice(_ identifier: String, completion: @escaping (String?) -> Void) {
        storeKit.retrieveProductsInfo([identifier]) { result in
            if let product = result.retrievedProducts.first {
                completion(product.localizedPrice)
            }
            else if let _ = result.invalidProductIDs.first {
                completion(nil)
            }
            else {
                completion(nil)
            }
        }
    }
    
    private func purchaseReceipt() {
        storeKit.fetchReceipt(forceRefresh: false) { [weak self] result in
            switch result {
            case .success(let receiptData):
                let encryptedReceipt = receiptData.base64EncodedString(options: [])
                self?.completion?((true, receipt: encryptedReceipt, error: nil))
            case .error(_):
                self?.completion?((false, receipt: nil, error: .receiptNotAvailable))
            }
        }
    }
    
    func restorePurchases() {
        guard let applicationUserName = OEXSession.shared()?.currentUser?.username else { return }

        storeKit.restorePurchases(atomically: false, applicationUsername: applicationUserName) { results in
            if results.restoreFailedPurchases.count > 0 {
                //TODO: Handle failed restore purchases
            }
            else if results.restoredPurchases.count > 0 {
                for _ in results.restoredPurchases {
                    //TODO: Handle restore purchases
                }
            }
        }
    }

    func markPurchaseComplete(_ courseID: String, type: TransctionType) {
        // Mark the purchase complete
        switch type {
        case .transction:
            if let purchase = purchasess[courseID] as? Purchase {
                if purchase.needsFinishTransaction {
                    storeKit.finishTransaction(purchase.transaction)
                }
            }
            break
        case .purchase:
            if let purchase = purchasess[courseID] as? PurchaseDetails {
                if purchase.needsFinishTransaction {
                    storeKit.finishTransaction(purchase.transaction)
                }
            }
            break
        }

        purchasess.removeValue(forKey: courseID)
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: CourseUpgradeCompleteNotification)))
    }
    
    func restoreFailedPurchase() {
        storeKit.restorePurchases { restoreResults in
            restoreResults.restoreFailedPurchases.forEach { error, _ in
                print(error)
            }
        }
    }
}
