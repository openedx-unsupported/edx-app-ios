//
//  CertificateViewController.swift
//  edX
//
//  Created by Michael Katz on 11/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import WebKit

class CertificateViewControlller: AuthenticatedWebViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let shareButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share")
        navigationItem.rightBarButtonItem = shareButton
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics?.trackScreenWithName(OEXAnalyticsScreenCertificate)
    }

    func share() {
        let text = Strings.Certificates.shareText
        let url = self.url!
        let controller = UIActivityViewController(activityItems: [text,url], applicationActivities: nil)
        controller.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll]
        controller.completionWithItemsHandler = {activityType, completed, _, error in
            if let type = activityType where completed {
                let analyticsType: String
                switch type {
                case UIActivityTypePostToTwitter:
                    analyticsType = "Twitter"
                case UIActivityTypePostToFacebook:
                    analyticsType = "Facebook"
                default:
                    analyticsType = "Other"
                }
                self.environment.analytics?.trackCertificateShared(url.absoluteString, type: analyticsType)
            }
        }
        presentViewController(controller, animated: true, completion: nil)
    }
}