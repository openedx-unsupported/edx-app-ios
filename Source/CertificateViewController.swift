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
        let text = "I took a course"
        let url = self.url!
        let image = UIImage(named: "courseCertificate")!
        let controller = UIActivityViewController(activityItems: [text,url,image], applicationActivities: nil)
        controller.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll]
        presentViewController(controller, animated: true, completion: nil)
    }
}