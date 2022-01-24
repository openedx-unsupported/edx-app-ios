//
//  CourseUpgradeCompletion.swift
//  edX
//
//  Created by Muhammad Umer on 16/12/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

let CourseUpgradeCompletionNotification = "CourseUpgradeCompletionNotification"

class CourseUpgradeCompletion {
    
    static let courseID = "CourseID"
    static let blockID = "BlockID"
    static let screen = "Screen"
    
    static let shared = CourseUpgradeCompletion()
    
    enum CompletionState {
        case success(_ courseID: String, _ componentID: String?)
        case error
    }
    
    private init() { }
    
    func handleCourseUpgrade(state: CompletionState, screen: ValuePropModalType) {
        switch state {
        case .success(let courseID, let blockID):
            let dictionary = [
                CourseUpgradeCompletion.screen: screen.rawValue,
                CourseUpgradeCompletion.courseID: courseID,
                CourseUpgradeCompletion.blockID: blockID
            ]
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: CourseUpgradeCompletionNotification), object: dictionary))
        case .error:
            showError()
        }
    }
    
    func showSuccess() {
        guard let topController = UIApplication.shared.topMostController() else { return }
        let alertController = UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.successAlertTitle, message: Strings.CourseUpgrade.successAlertMessage, cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }
        alertController.addButton(withTitle: Strings.CourseUpgrade.successAlertContinue, style: .cancel) { action in
            
        }
    }
    
    func showError() {
        guard let topController = UIApplication.shared.topMostController() else { return }
        let alertController = UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.failureAlertTitle, message: Strings.CourseUpgrade.failureAlertMessage, cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }
        alertController.addButton(withTitle: Strings.CourseUpgrade.failureAlertGetHelp) { action in
            
        }
        alertController.addButton(withTitle: Strings.close, style: .default) { action in
            
        }
    }
}
