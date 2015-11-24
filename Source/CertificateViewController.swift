//
//  CertificateViewController.swift
//  edX
//
//  Created by Michael Katz on 11/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import WebKit

class CertificateViewController: AuthenticatedWebViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let shareButton = UIBarButtonItem(barButtonSystemItem: .Action, target: nil, action: nil)
        shareButton.oex_setAction { [weak self] in
            self?.share()
        }
        navigationItem.rightBarButtonItem = shareButton

        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics?.trackScreenWithName(OEXAnalyticsScreenCertificate)
    }

    func share() {
        let text = Strings.Certificates.shareText
        let url = self.currentUrl!
        let controller = UIActivityViewController(activityItems: [text,url], applicationActivities: nil)
        controller.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll]
        controller.completionWithItemsHandler = {activityType, completed, _, error in
            if let type = activityType where completed {
                let analyticsType: String
                switch type {
                case UIActivityTypePostToTwitter:
                    analyticsType = "twitter"
                case UIActivityTypePostToFacebook:
                    analyticsType = "facebook"
                default:
                    analyticsType = "other"
                }
                self.environment.analytics?.trackCertificateShared(url.absoluteString, type: analyticsType)
            }
        }
        presentViewController(controller, animated: true, completion: nil)
    }
}