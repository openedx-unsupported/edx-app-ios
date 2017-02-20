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
        let osVersionText = Strings.SubmitFeedback.osVersion(version: UIDevice.currentDevice().systemVersion)
        let appVersionText = Strings.SubmitFeedback.appVersion(version: NSBundle.mainBundle().oex_shortVersionString(), build: NSBundle.mainBundle().oex_buildVersionString())
        let deviceModelText = Strings.SubmitFeedback.deviceModel(model: UIDevice.currentDevice().model)
        let body = ["\n", Strings.SubmitFeedback.marker, osVersionText, appVersionText, deviceModelText].joinWithSeparator("\n")
        return body
    }
    
}
