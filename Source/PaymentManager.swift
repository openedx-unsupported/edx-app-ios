//
//  PaymentManager.swift
//  edX
//
//  Created by Muhammad Umer on 22/06/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
import SwiftyStoreKit

let productID = "org.edx.mobile.integrationtest"
let simulatesAskToBuyInSandbox: Bool = false
private let CourseUpgradeCompleteNotification: String = "CourseUpgradeCompleteNotification"


// In case of completeTransctions SDK returns SwiftyStoreKit.Purchase and on the in-app purchase SDK returns SwiftyStoreKit.PurchaseDetails
enum TransctionType: String {
    case transction
    case purchase
}

enum PurchaseError: String {
    case paymentsNotAvailebe // Device isn't allowed to make payments
    case invalidUser // App User isn't available
    case purchaseError // Unable to purchase a product
    case receiptNotAvailable // Unable to fetech inapp purchase receipt
    case invalidBasketID // Order basket ID is invalid
}

@objc class PaymentManager: NSObject {
    private typealias storeKit = SwiftyStoreKit
    @objc static let shared = PaymentManager()
    // Use this dictionary to keep track of inprocess transctions and allow only one transction at a time
    private var purchasess: [String: Any] = [:]

    typealias PurchaseCompletionHandler = ((success: Bool, receipt: String?, error: PurchaseError?)) -> Void
    var completion: PurchaseCompletionHandler?


    lazy var isIAPInprocess:Bool = {
        return purchasess.count > 0
    }()

    lazy var inprocessPurchases: [String: Any] = {
        return purchasess
    }()

    @objc func completeTransactions() {
        // save and check if purchase is already there
        storeKit.completeTransactions(atomically: false) { [weak self] purchases in // atomically = false
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    let downloads = purchase.transaction.downloads
                    if !downloads.isEmpty {
                        SwiftyStoreKit.start(downloads)
                    } else if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        // SwiftyStoreKit.finishTransaction(purchase.transaction)
                        self?.purchasess[purchase.productId] =  purchase
                        self?.markPurchaseComplete(productID, type: .transction)
                    }
                    print("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break // do nothing
                }
            }
        }
    }

    func purchase() {
        let productId = ""
        let applicationUserName = ""
        
        storeKit.purchaseProduct(productId, atomically: false, applicationUsername: applicationUserName) { result in
            print(result)
        }
    }
    
    func getReceipt() {
        storeKit.fetchReceipt(forceRefresh: true) { _ in
            
        }
    }
    
    func verify() {
        
    }
    
    func restorePurchase() {
        let applicationUserName = ""
        storeKit.restorePurchases(atomically: false, applicationUsername: applicationUserName) { restoreResults in
            for purchase in restoreResults.restoredPurchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    print("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break // do nothing
                }}}}
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

        storeKit.purchaseProduct(identifier, atomically: false, applicationUsername: applicationUserName, simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox) { [weak self] result in
            switch result {
            case .success(let purchase):
                self?.purchasess[purchase.productId] = purchase
                self?.fetchPurchaseReceipt()
                break
            case .error(let error):
                completion?((false, receipt: nil, error: .purchaseError))
                switch error.code {
                case .unknown:
                    print("Unknown error. Please contact support")
                    break
                case .clientInvalid:
                    print("Not allowed to make the payment")
                    break
                case .paymentCancelled:
                    print("payment cancled")
                    break

                case .paymentInvalid:
                    print("The purchase identifier was invalid")
                    break
                case .paymentNotAllowed:
                    print("The device is not allowed to make the payment")
                    break
                case .storeProductNotAvailable:
                    print("The product is not available in the current storefront")
                    break
                case .cloudServicePermissionDenied:
                    print("Access to cloud service information is not allowed")
                    break
                case .cloudServiceNetworkConnectionFailed:
                    print("Could not connect to the network")
                    break
                case .cloudServiceRevoked:
                    print("User has revoked permission to use this cloud service")
                    break
                default: print((error as NSError).localizedDescription)
                }
            }
        }
    }

    func retrieveProductsInfo(_ identifier: String, completion: @escaping (String?) -> Void) {
        storeKit.retrieveProductsInfo([identifier]) { result in
            if let product = result.retrievedProducts.first {
                completion(product.localizedPrice)
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
                completion(nil)
            }
            else {
                completion(nil)
                print("Error: \(String(describing: result.error))")
            }
        }
    }
    
    private func fetchPurchaseReceipt() {
        storeKit.fetchReceipt(forceRefresh: false) { [weak self] result in
            switch result {
            case .success(let receiptData):
                let encryptedReceipt = receiptData.base64EncodedString(options: [])
                self?.completion?((true, receipt: encryptedReceipt, error: nil))
            case .error(let error):
                print("Fetch receipt failed: \(error)")
                self?.completion?((false, receipt: nil, error: .receiptNotAvailable))
            }
        }
    }
    
    func restorePurchases() {
        guard let applicationUserName = OEXSession.shared()?.currentUser?.username else { return }

        storeKit.restorePurchases(atomically: false, applicationUsername: applicationUserName) { results in
            if results.restoreFailedPurchases.count > 0 {
                print("Restore Failed. Please try again.")
            }
            else if results.restoredPurchases.count > 0 {
                for purchase in results.restoredPurchases {
                    //handle restore purchases
                    print(purchase)
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
