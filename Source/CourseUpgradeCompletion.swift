//
//  CourseUpgradeCompletion.swift
//  edX
//
//  Created by Muhammad Umer on 16/12/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

let CourseUpgradeCompletionNotification = "CourseUpgradeCompletionNotification"

struct CourseUpgradeModel {
    let courseID: String
    let blockID: String?
    let screen: CourseUpgradeScreen
}

class CourseUpgradeCompletion {
    
    static let courseID = "CourseID"
    static let blockID = "BlockID"
    static let screen = "Screen"
    
    static let shared = CourseUpgradeCompletion()
    
    enum CompletionState {
        case intermediate
        case success(_ courseID: String, _ componentID: String?)
        case error
    }
    
    var courseUpgradeModel: CourseUpgradeModel?
        
    private init() { }
    
    func handleCourseUpgrade(state: CompletionState, screen: CourseUpgradeScreen) {
        switch state {
        case .intermediate:
            ValuePropUnlockViewContainer.shared.showView()
            break
        case .success(let courseID, let blockID):
            courseUpgradeModel = CourseUpgradeModel(courseID: courseID, blockID: blockID, screen: screen)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: CourseUpgradeCompletionNotification), object: nil))
            break
        case .error:
            ValuePropUnlockViewContainer.shared.removeView { [weak self] in
                self?.showError()
            }
            break
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
