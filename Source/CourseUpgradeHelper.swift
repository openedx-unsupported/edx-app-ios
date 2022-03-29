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

protocol CourseUpgradeHelperDelegate: AnyObject {
    func hideAlertAction()
}

class CourseUpgradeHelper: NSObject {
    
    static let courseID = "CourseID"
    static let blockID = "BlockID"
    static let screen = "Screen"
    
    static let shared = CourseUpgradeHelper()
    private lazy var unlockController = ValuePropUnlockViewContainer()
    weak var delegate: CourseUpgradeHelperDelegate?

    enum CompletionState {
        case fulfillment
        case success(_ courseID: String, _ componentID: String?)
        case error(PurchaseError)
    }

    private var upgradeModel: CourseUpgradeModel?

    var courseUpgradeModel: CourseUpgradeModel? {
        get {
            return upgradeModel
        }
    }
        
    private override init() { }
    
    func handleCourseUpgrade(state: CompletionState, screen: CourseUpgradeScreen, delegate: CourseUpgradeHelperDelegate? = nil) {
        self.delegate = delegate
        switch state {
        case .fulfillment:
            showLoader()
            break
        case .success(let courseID, let blockID):
            upgradeModel = CourseUpgradeModel(courseID: courseID, blockID: blockID, screen: screen)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: CourseUpgradeCompletionNotification), object: nil))
            break
        case .error(let type):
            removeLoader(success: false, removeView: type != .verifyReceiptError, controller: nil, selector: nil)
            break
        }
    }

    func resetUpgradeModel() {
        upgradeModel = nil
        delegate = nil
    }
    
    func showSuccess() {
        guard let topController = UIApplication.shared.topMostController() else { return }
        topController.showBottomActionSnackBar(message: Strings.CourseUpgrade.successMessage, textSize: .xSmall, autoDismiss: true, duration: 3)
    }
    
    func showError(controller: UIViewController? = nil, selector: Selector? = nil) {
        guard let topController = UIApplication.shared.topMostController() else { return }

        let alertController = UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.FailureAlert.alertTitle, message: CourseUpgradeHandler.shared.errorMessage, cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }

        if case .error (let type, _) = CourseUpgradeHandler.shared.upgradeState {
            if type == .verifyReceiptError {
                alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.refreshToRetry, style: .default) {action in
                    CourseUpgradeHandler.shared.reverifyPayment()
                }
            }
        }

        if case .complete = CourseUpgradeHandler.shared.upgradeState, (controller != nil && selector != nil) {
            alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.refreshToRetry, style: .default) {[weak self] action in
                self?.showLoader()
                controller?.perform(selector)
            }
        }

        alertController.addButton(withTitle: Strings.CourseUpgrade.failureAlertGetHelp) { [weak self] action in
            self?.launchEmailComposer(errorMessage: "Error: \(CourseUpgradeHandler.shared.formattedError)")
        }

        alertController.addButton(withTitle: Strings.close, style: .default) { [weak self] action in
            if self?.unlockController.isVisible ?? false {
                self?.unlockController.removeView() {
                    self?.delegate?.hideAlertAction()
                    self?.resetUpgradeModel()
                }
            }
            else {
                self?.delegate?.hideAlertAction()
                self?.resetUpgradeModel()
            }
        }
    }
    
    func showLoader() {
        if !unlockController.isVisible {
            unlockController.showView()
        }
    }
    
    func removeLoader(success: Bool? = false, removeView: Bool? = false, controller: UIViewController? = nil, selector: Selector? = nil) {
        if success == true {
            upgradeModel = nil
        }

        if unlockController.isVisible, removeView == true {
            unlockController.removeView() { [weak self] in
                if let success = success {
                    if success {
                        self?.showSuccess()
                    } else {
                        self?.showError(controller: controller, selector: selector)
                    }
                }
            }
        } else if success == false {
            showError(controller: controller, selector: selector)
        }
    }
}

extension CourseUpgradeHelper: MFMailComposeViewControllerDelegate {
    fileprivate func launchEmailComposer(errorMessage: String) {
        guard let controller = UIApplication.shared.topMostController() else { return }

        if !MFMailComposeViewController.canSendMail() {
            UIAlertController().showAlert(withTitle: Strings.emailAccountNotSetUpTitle, message: Strings.emailAccountNotSetUpMessage, onViewController: controller)
        } else {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.navigationBar.tintColor = OEXStyles.shared().navigationItemTintColor()
            mail.setSubject(Strings.CourseUpgrade.getSupportEmailSubject)
            let body = EmailTemplates.supportEmailMessageTemplate(error: errorMessage)
            mail.setMessageBody(body, isHTML: false)
            if let fbAddress = OEXRouter.shared().environment.config.feedbackEmailAddress() {
                mail.setToRecipients([fbAddress])
            }
            controller.present(mail, animated: true, completion: nil)
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        guard let controller = UIApplication.shared.topMostController() else { return }
        controller.dismiss(animated: true, completion: { [weak self] in
            if self?.unlockController.isVisible ?? false {
                self?.unlockController.removeView(completion: {
                    self?.delegate?.hideAlertAction()
                    self?.resetUpgradeModel()
                })
            }
            else {
                self?.delegate?.hideAlertAction()
                self?.resetUpgradeModel()
            }
        })
    }
}
