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
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenCertificate)
    }

    func share() {
        let text = Strings.Certificates.shareText
        let url = self.currentUrl!
        let controller = shareTextAndALink(text, url: url) { analyticsType in
            self.environment.analytics.trackCertificateShared(url.absoluteString, type: analyticsType)
        }
        presentViewController(controller, animated: true, completion: nil)
    }
}