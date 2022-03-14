//
//  EmailTemplateDataFactory.swift
//  edX
//
//  Created by Danial Zahid on 2/20/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

@objc class EmailTemplates: NSObject {
    
    @objc static func supportEmailMessageTemplate(error: String? = nil) -> String {
        let osVersionText = Strings.SubmitFeedback.osVersion(version: UIDevice.current.systemVersion)
        let appVersionText = Strings.SubmitFeedback.appVersion(version: Bundle.main.oex_shortVersionString(), build: Bundle.main.oex_buildVersionString())
        let deviceModelText = Strings.SubmitFeedback.deviceModel(model: UIDevice.current.model)
        var body = ["\n", Strings.SubmitFeedback.marker, osVersionText, appVersionText, deviceModelText]
        if let error = error {
            body.append(error)
        }
        return body.joined(separator: "\n")
    }
    
}
