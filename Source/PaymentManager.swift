//
//  PaymentManager.swift
//  edX
//
//  Created by Muhammad Umer on 22/06/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
import SwiftyStoreKit

let UnfullfilledTransctionsNotification: String = "UnfullfilledTransctionsNotification"

// In case of completeTransctions SDK returns SwiftyStoreKit.Purchase
// And on the in-app purchase SDK returns SwiftyStoreKit.PurchaseDetails
enum TransctionType: String {
    case transction
    case purchase
}

enum PurchaseError: String {
    case paymentsNotAvailable // device isn't allowed to make payments
    case invalidUser // app user isn't available
    case paymentError // unable to purchase a product
    case receiptNotAvailable // unable to fetech inapp purchase receipt
    case basketError // basket API returns error
    case checkoutError // checkout API returns error
    case verifyReceiptError // verify receipt API returns error
    case generalError // general error
    case alreadyPurchased // Course is already purchased on the same device

    var errorString: String {
        switch self {
        case .basketError:
            return "basket"
        case .checkoutError:
            return "checkout"
        case .paymentError:
            return "payment"
        case .verifyReceiptError:
            return "execute"
        default:
            return ""
        }
    }
}

@objc class PaymentManager: NSObject {
    private typealias storeKit = SwiftyStoreKit
    @objc static let shared = PaymentManager()
    // Use this dictionary to keep track of inprocess transctions and allow only one transction at a time
    private(set) var purchases: [String: Any] = [:]

    typealias PurchaseCompletionHandler = ((success: Bool, receipt: String?, error: (type: PurchaseError?, error: Error?)?)) -> Void
    var completion: PurchaseCompletionHandler?

    var unfinishedPurchases:Bool {
        return !purchases.isEmpty
    }

    var inprocessPurchases: [String: Any] {
        return purchases
    }

    var unfinishedProductIDs: [String] {
        var productIDs: [String] = []
        for productID in purchases.keys {
            productIDs.append(productID)
        }

        return productIDs
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
//                         SwiftyStoreKit.finishTransaction(purchase.transaction)
                        self?.purchases[purchase.productId] =  purchase
                    }
                case .failed, .purchasing, .deferred:
                    // TODO: Will handle while implementing the final version
                    // At the momewnt don't have anything to add here
                    break // do nothing
                @unknown default:
                    break // do nothing
                }
            }

            if !purchases.isEmpty {
                NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: UnfullfilledTransctionsNotification)))
            }
        }
    }

    func purchaseProduct(_ identifier: String, completion: PurchaseCompletionHandler?) {
        guard storeKit.canMakePayments else {
            if let controller = UIApplication.shared.topMostController() {
                UIAlertController().showAlert(withTitle: "Payment Error", message: "This device is not able or allowed to make payments", onViewController: controller)
            }
            completion?((false, receipt: nil, error:(type: .paymentsNotAvailable, error: nil)))
            return
        }

        guard let applicationUserName = OEXSession.shared()?.currentUser?.username else {
            completion?((false, receipt: nil, error: (type: .invalidUser, error: NSError(domain: "edx.app.payment", code: 1010, userInfo: [NSLocalizedDescriptionKey : "App username is not available"]))))
            return
        }
        self.completion = completion

        storeKit.purchaseProduct(identifier, atomically: false, applicationUsername: applicationUserName) { [weak self] result in
            switch result {
            case .success(let purchase):
                self?.purchases[purchase.productId] = purchase
                self?.purchaseReceipt()
                break
            case .error(let error):
                completion?((false, receipt: nil, error: (type: .paymentError, error: error)))
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
            case .deferred(let purchase):
                print(purchase.product.productIdentifier)
            @unknown default:
                completion?((false, receipt: nil, error: nil))
            }
        }
    }

    func productPrice(_ identifier: String, completion: ((String?) -> Void)? = nil) {
        storeKit.retrieveProductsInfo([identifier]) { result in
            if let product = result.retrievedProducts.first {
                completion?(product.localizedPrice)
            }
            else if let _ = result.invalidProductIDs.first {
                completion?(nil)
            }
            else {
                completion?(nil)
            }
        }
    }
    
    func purchaseReceipt(completion: PurchaseCompletionHandler? = nil) {
        if let completion = completion {
            self.completion = completion
        }

        storeKit.fetchReceipt(forceRefresh: false) { [weak self] result in
            switch result {
            case .success(let receiptData):
                let encryptedReceipt = receiptData.base64EncodedString(options: [])
                self?.completion?((true, receipt: encryptedReceipt, error: nil))
            case .error(let error):
                self?.completion?((false, receipt: nil, error: (type: .receiptNotAvailable, error: error)))
            @unknown default:
                self?.completion?((false, receipt: nil, error: nil))
            }
        }
    }
    
    func restorePurchases(completion: ((_ success: Bool, _ purchases: [Purchase]?) -> ())? = nil) {
        guard let applicationUserName = OEXSession.shared()?.currentUser?.username else { return }

        storeKit.restorePurchases(atomically: false, applicationUsername: applicationUserName) { results in
            if !results.restoredPurchases.isEmpty {
                completion?(true, results.restoredPurchases)
            }
            else {
                completion?(false, nil)
            }
        }
    }

    func alreadyPurchased(_ identifier: String, completion: ((_ success: Bool) -> ())? = nil) {
        restorePurchases { success, purchases in
            if success {
                for p in purchases ?? [] {
                    if p.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(p.transaction)
                    }
                }
                for purchase in purchases ?? [] where purchase.productId == identifier {
                    completion?(true)
                    return
                }
                completion?(false)
            }
            else {
                completion?(false)
            }
        }
    }

    func markPurchaseComplete(_ productID: String, type: TransctionType) {
        // Mark the purchase complete
        switch type {
        case .transction:
            if let purchase = purchases[productID] as? Purchase {
                if purchase.needsFinishTransaction {
                    storeKit.finishTransaction(purchase.transaction)
                }
            }
            break
        case .purchase:
            if let purchase = purchases[productID] as? PurchaseDetails {
                if purchase.needsFinishTransaction {
                    storeKit.finishTransaction(purchase.transaction)
                }
            }
            break
        }

        removePurchase(productID)
    }

    func removePurchase(_ productID: String) {
        purchases.removeValue(forKey: productID)
    }
    
    func restoreFailedPurchase() {
        storeKit.restorePurchases { restoreResults in
            restoreResults.restoreFailedPurchases.forEach { error, _ in
                print(error)
            }
        }
    }
}
