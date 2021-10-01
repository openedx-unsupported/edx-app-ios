//
//  EnrolledCoursesViewController+Banner.swift
//  edX
//
//  Created by Saeed Bashir on 9/29/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

//Banner handling
extension EnrolledCoursesViewController: BannerViewControllerDelegate {
    func handleBanner() {
        if !handleBannerOnStart || environment.session.currentUser == nil {
            return
        }

        if let _ = UIApplication.shared.topMostController() as? BannerViewController {
            return
        }

        let delegate = UIApplication.shared.delegate as? OEXAppDelegate
        let delay: Double = (delegate?.openedFromDeeplink ?? false) ? 10 : 5
        delegate?.openedFromDeeplink = false

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.fetchBanner()
        }
    }

    private func fetchBanner() {
        let request = BannerAPI.unacknowledgedAPI()

        environment.networkManager.taskForRequest(request) { [weak self] result in
            guard let weakSelf = self,
                  let topController = UIApplication.shared.keyWindow?.rootViewController! else { return }
//            if let link = result.data?.first,
            // opening a random link for testing
               if let url = URL(string: "https://www.google.com.pk") {
                self?.environment.router?.showBannerViewController(from: topController, url: url, delegate: weakSelf)
            }
        }
    }

    private func showBanner(with link: String, requireAuth: Bool) {

    }

//    private func acknowledge() {
//        let request = NetworkRequest<String>(
//            method: .POST,
//            path: "/notices/api/v1/acknowledge",
//            requiresAuth: true,
//            body: .jsonBody(JSON([
//                "notice_id": "",
//                "acknowledgment_type": "confirmed"
//            ])),
//            deserializer: .noContent({ response in
//                if response.statusCode == OEXHTTPStatusCode.code200OK.rawValue {
//                    print("success")
//                    return Success(v: "success")
//                } else {
//                    print("failure")
//                    return Failure()
//                }
//        }))
//        environment.networkManager.taskForRequest(request) { result in
//            print(result.data)
//        }
//    }

    //MARK:- BannerViewControllerDelegate
    func didTapOnAcknowledge() {
//        acknowledge()
    }

    func didTapOnDeleteAccount() {

    }
}
