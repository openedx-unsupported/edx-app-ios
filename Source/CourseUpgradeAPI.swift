//
//  CourseUpgradeAPI.swift
//  edX
//
//  Created by Saeed Bashir on 8/17/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

private let PaymentProcessor = "ios-iap"

public struct CourseUpgradeAPI {
    static let baseURL = OEXRouter.shared().environment.config.ecommerceURL ?? ""
    private static func basketDeserializer(response: HTTPURLResponse, json: JSON) -> Result<OrderBasket> {
        guard response.httpStatusCode.is2xx else {
            return Failure(e: NSError(domain: "BasketApiErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: json]))
        }
        return Success(v: OrderBasket(json: json))
    }
    
    static func basketAPI(with sku: String) -> NetworkRequest<OrderBasket> {
        let path = "/api/iap/v1/basket/add/?sku={sku}".oex_format(withParameters: ["sku" : sku])
        
        return NetworkRequest(
            method: .GET,
            path: path,
            requiresAuth: true,
            deserializer: .jsonResponse(basketDeserializer))
    }
    
    private static func checkoutDeserializer(response: HTTPURLResponse, json: JSON) -> Result<CheckoutBasket> {
        guard response.httpStatusCode.is2xx else {
            return Failure(e: NSError(domain: "CheckoutApiErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: json]))
        }
        return Success(v: CheckoutBasket(json: json))
    }

    static func checkoutAPI(basketID: Int) -> NetworkRequest<CheckoutBasket> {
        return NetworkRequest(
            method: .POST,
            path: "/api/iap/v1/checkout/",
            requiresAuth: true,
            body: .jsonBody(JSON([
                "basket_id": basketID,
                "payment_processor": PaymentProcessor
            ] as [String : Any])),
            deserializer: .jsonResponse(checkoutDeserializer)
        )
    }
    
    private static func executeDeserializer(response: HTTPURLResponse, json: JSON) -> Result<OrderVerify> {
        guard response.httpStatusCode.is2xx else {
            return Failure(e: NSError(domain: "ExecuteApiErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: json]))
        }
        return Success(v: (OrderVerify(json: json)))
    }

    static func executeAPI(basketID: Int, price: NSDecimalNumber, currencyCode: String, receipt: String) -> NetworkRequest<OrderVerify> {
        return NetworkRequest(
            method: .POST,
            path: "/api/iap/v1/execute/",
            requiresAuth: true,
            body: .jsonBody(JSON([
                "basket_id": basketID,
                "price": price,
                "currency_code": currencyCode,
                "purchase_token": receipt,
                "payment_processor": PaymentProcessor
            ] as [String : Any])),
            deserializer: .jsonResponse(executeDeserializer)
        )
    }
}

struct OrderBasket {
    let success: String
    let basketID: Int
    
    init(json: JSON) {
        success = json["success"].string ?? ""
        basketID = json["basket_id"].int ?? 0
    }
}

struct CheckoutBasket {
    let paymentPageURL: String

    init(json: JSON) {
        paymentPageURL = json["payment_page_url"].string ?? ""
    }
}

struct OrderVerify {
    let status: String
    let number: String
    let currency: String

    init(json: JSON) {
        status = json["status"].string ?? ""
        number = json["number"].string ?? ""
        currency = json["currency"].string ?? ""
    }
}
