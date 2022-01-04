//
//  AppleSocial.swift
//  edX
//
//  Created by Saeed Bashir on 8/24/20.
//  Copyright © 2020 edX. All rights reserved.
//

import AuthenticationServices

private let errorDomain = "AppleSocial"

typealias AppleLoginCompletionHandler = (OEXRegisteringUserDetails?, _ accessToken: String?, Error?) -> Void


class AppleSocial: NSObject {

    static let shared = AppleSocial()
    private var completionHandler: AppleLoginCompletionHandler?

    private override init() {
        super.init()
    }

    func loginFromController(controller : UIViewController, completion: @escaping AppleLoginCompletionHandler) {
        
        completionHandler = completion
        
        let authorizationProvider = ASAuthorizationAppleIDProvider()
        let request = authorizationProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension AppleSocial: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completionHandler?(nil, nil, error)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        guard let credentials = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let error = NSError(domain: errorDomain, code: ASAuthorizationError.unknown.rawValue, userInfo: [NSLocalizedDescriptionKey: "Failed to get credentials"])
            completionHandler?(nil, nil, error)
            return
        }

        let firstName = credentials.fullName?.givenName
        let lastName = credentials.fullName?.familyName
        let email = credentials.email ?? ""

        let userDetails = OEXRegisteringUserDetails()
        userDetails.name = "\(firstName ?? "") \(lastName ?? "")"
        userDetails.email = email

        if let data = credentials.identityToken, let code = String(data: data, encoding: .utf8) {
            if userDetails.email?.isEmpty ?? true {
                let tokenDetails = try? decode(jwtToken: code)
                userDetails.email = tokenDetails?["email"] as? String ?? ""
            }
            completionHandler?(userDetails, code, nil)
        }
        else {
            let error = NSError(domain: errorDomain, code: ASAuthorizationError.failed.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unable to extract apple identity token"])
            completionHandler?(nil, nil, error)
        }
    }

    private func decode(jwtToken jwt: String) throws -> [String: Any] {

      enum DecodeErrors: Error {
          case badToken
          case other
      }

      func base64Decode(_ base64: String) throws -> Data {
          let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
          guard let decoded = Data(base64Encoded: padded) else {
              throw DecodeErrors.badToken
          }
          return decoded
      }

      func decodeJWTPart(_ value: String) throws -> [String: Any] {
          let bodyData = try base64Decode(value)
          let json = try JSONSerialization.jsonObject(with: bodyData, options: [])
          guard let payload = json as? [String: Any] else {
              throw DecodeErrors.other
          }
          return payload
      }

      let segments = jwt.components(separatedBy: ".")
      return try decodeJWTPart(segments[1])
    }

}

extension AppleSocial: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.window ?? UIApplication.shared.windows[0]
    }
}
