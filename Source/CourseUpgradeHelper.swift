//
//  CourseUpgradeHelper.swift
//  edX
//
//  Created by Muhammad Umer on 16/12/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
import MessageUI

let CourseUpgradeCompletionNotification = "CourseUpgradeCompletionNotification"

struct CourseUpgradeModel {
    let courseID: String
    let blockID: String?
    let screen: CourseUpgradeScreen
}

class CourseUpgradeHelper: NSObject {
    
    static let courseID = "CourseID"
    static let blockID = "BlockID"
    static let screen = "Screen"
    
    static let shared = CourseUpgradeHelper()
    
    enum CompletionState {
        case fulfillment
        case success(_ courseID: String, _ componentID: String?)
        case error
    }
    
    var courseUpgradeModel: CourseUpgradeModel?
        
    private override init() { }
    
    func handleCourseUpgrade(state: CompletionState, screen: CourseUpgradeScreen) {
        switch state {
        case .fulfillment:
            showLoader()
            break
        case .success(let courseID, let blockID):
            courseUpgradeModel = CourseUpgradeModel(courseID: courseID, blockID: blockID, screen: screen)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: CourseUpgradeCompletionNotification), object: nil))
            break
        case .error:
            removeLoader(success: false)
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
        alertController.addButton(withTitle: Strings.CourseUpgrade.failureAlertGetHelp) { [weak self] action in
            self?.launchEmailComposer()
        }
        alertController.addButton(withTitle: Strings.close, style: .default) { action in
            
        }
    }
    
    func showLoader() {
        ValuePropUnlockViewContainer.shared.showView()
    }
    
    func removeLoader(success: Bool? = nil) {
        courseUpgradeModel = nil
        
        ValuePropUnlockViewContainer.shared.removeView() { [weak self] in
            if let success = success {
                if success {
                    self?.showSuccess()
                } else {
                    self?.showError()
                }
            }
        }
    }
}

extension CourseUpgradeHelper: MFMailComposeViewControllerDelegate {
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
