//
//  CourseUpgradeCompletion.swift
//  edX
//
//  Created by Muhammad Umer on 16/12/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
import MessageUI

let CourseUpgradeCompletionNotification = "CourseUpgradeCompletionNotification"

class CourseUpgradeCompletion: NSObject {
    
    static let courseID = "CourseID"
    static let blockID = "BlockID"
    static let screen = "Screen"
    
    static let shared = CourseUpgradeCompletion()
    
    enum CompletionState {
        case success(_ courseID: String, _ componentID: String?)
        case error
    }
    
    private override init() { }
    
    func handleCourseUpgrade(state: CompletionState, screen: CourseUpgradeScreen) {
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
        alertController.addButton(withTitle: Strings.CourseUpgrade.failureAlertGetHelp) { [weak self] action in
            self?.launchEmailComposer()
        }
        alertController.addButton(withTitle: Strings.close, style: .default) { action in
            
        }
    }
}

extension CourseUpgradeCompletion: MFMailComposeViewControllerDelegate {
    fileprivate func launchEmailComposer() {
        guard let controller = UIApplication.shared.window?.rootViewController else { return }

        if !MFMailComposeViewController.canSendMail() {
            UIAlertController().showAlert(withTitle: Strings.emailAccountNotSetUpTitle, message: Strings.emailAccountNotSetUpMessage, onViewController: controller)
        } else {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.navigationBar.tintColor = OEXStyles.shared().navigationItemTintColor()
            mail.setSubject(Strings.CourseUpgrade.getSupportEmailSubject)

            mail.setMessageBody(EmailTemplates.supportEmailMessageTemplate(), isHTML: false)
            if let fbAddress = OEXRouter.shared().environment.config.feedbackEmailAddress() {
                mail.setToRecipients([fbAddress])
            }
            controller.present(mail, animated: true, completion: nil)

        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        guard let controller = UIApplication.shared.window?.rootViewController else { return }

        controller.dismiss(animated: true, completion: nil)
    }
}
