//
//  EmailTemplateDataFactory.swift
//  edX
//
//  Created by Danial Zahid on 2/20/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class EmailTemplates {
    
    static func supportEmailMessageTemplate() -> String {
        let osVersionText = Strings.SubmitFeedback.osVersion(version: UIDevice.current.systemVersion)
        let appVersionText = Strings.SubmitFeedback.appVersion(version: Bundle.main.oex_shortVersionString(), build: Bundle.main.oex_buildVersionString())
        let deviceModelText = Strings.SubmitFeedback.deviceModel(model: UIDevice.current.model)
        let body = ["\n", Strings.SubmitFeedback.marker, osVersionText, appVersionText, deviceModelText].joined(separator: "\n")
        return body
    }
    
}
