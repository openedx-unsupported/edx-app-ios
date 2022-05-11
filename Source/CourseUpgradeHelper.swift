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
    
    typealias Environment = OEXAnalyticsProvider
    
    static let shared = CourseUpgradeHelper()
    private lazy var unlockController = ValuePropUnlockViewContainer()
    weak private(set) var delegate: CourseUpgradeHelperDelegate?
    private(set) var completion: (()-> ())? = nil

    enum CompletionState {
        case initial
        case payment
        case fulfillment
        case success(_ courseID: String, _ componentID: String?)
        case error(PurchaseError, Error?)
    }
    
    // These error actions are used to send in analytics
    enum ErrorAction: String {
        case refreshToRetry = "refresh"
        case reloadPrice = "reload_price"
        case emailSupport = "get_help"
        case close = "close"
    }
    
    private(set) var courseUpgradeModel: CourseUpgradeModel?
    
    // These times are being used in analytics
    private var startTime: CFTimeInterval?
    private var refreshTime: CFTimeInterval?
    private var paymentStartTime: CFTimeInterval?
    private var contentUpgradeTime: CFTimeInterval?
    
    private var environment: Environment?
    private var pacing: String?
    private var courseID: CourseBlockID?
    private var blockID: CourseBlockID?
    private var screen: CourseUpgradeScreen = .none
    private var coursePrice: String?
        
    private override init() { }
    
    func setupHelperData(environment: Environment, pacing: String, courseID: CourseBlockID, blockID: CourseBlockID? = nil, coursePrice: String, screen: CourseUpgradeScreen) {
        self.environment = environment
        self.pacing = pacing
        self.courseID = courseID
        self.blockID = blockID
        self.coursePrice = coursePrice
        self.screen = screen
    }

    func resetUpgradeModel() {
        courseUpgradeModel = nil
        delegate = nil
    }

    func clearData() {
        environment = nil
        pacing = nil
        courseID = nil
        blockID = nil
        coursePrice = nil
        screen = .none
        refreshTime = nil
        startTime = nil

        resetUpgradeModel()
    }
    
    func handleCourseUpgrade(state: CompletionState, delegate: CourseUpgradeHelperDelegate? = nil) {
        self.delegate = delegate
        
        switch state {
        case .initial:
            startTime = CFAbsoluteTimeGetCurrent()
            break
        case .payment:
            paymentStartTime = CFAbsoluteTimeGetCurrent()
            break
        case .fulfillment:
            contentUpgradeTime = CFAbsoluteTimeGetCurrent()
            let endTime = CFAbsoluteTimeGetCurrent() - (paymentStartTime ?? 0)
            environment?.analytics.trackCourseUpgradePaymentTime(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, elapsedTime: endTime.millisecond)
            showLoader()
            break
        case .success(let courseID, let blockID):
            courseUpgradeModel = CourseUpgradeModel(courseID: courseID, blockID: blockID, screen: screen)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: CourseUpgradeCompletionNotification), object: nil))
            break
        case .error(let type, _):
            if type == .paymentError {
                environment?.analytics.trackCourseUpgradePaymentError(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, paymentError: CourseUpgradeHandler.shared.formattedError)
            }

            environment?.analytics.trackCourseUpgradeError(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, upgradeError: CourseUpgradeHandler.shared.formattedError)

            removeLoader(success: false, removeView: type != .verifyReceiptError)
            break
        }
    }
    
    func showSuccess() {
        guard let topController = UIApplication.shared.topMostController() else { return }
        topController.showBottomActionSnackBar(message: Strings.CourseUpgrade.successMessage, textSize: .xSmall, autoDismiss: true, duration: 3)

        let contentTime = CFAbsoluteTimeGetCurrent() - (contentUpgradeTime ?? 0)
        environment?.analytics.trackCourseUpgradeDuration(isRefresh: false, courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, elapsedTime: contentTime.millisecond)
        
        if let refreshTime = refreshTime {
            let refreshEndTime = CFAbsoluteTimeGetCurrent() - refreshTime
            
            environment?.analytics.trackCourseUpgradeDuration(isRefresh: true, courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, elapsedTime: refreshEndTime.millisecond)
        }

        let endTime = CFAbsoluteTimeGetCurrent() - (startTime ?? 0)
        environment?.analytics.trackCourseUpgradeSuccess(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", price: coursePrice ?? "", screen: screen, elapsedTime: endTime.millisecond)

        clearData()
    }
    
    func showError() {
        guard let topController = UIApplication.shared.topMostController() else { return }

        let alertController = UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.FailureAlert.alertTitle, message: CourseUpgradeHandler.shared.errorMessage, cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }

        if case .error (let type, _) = CourseUpgradeHandler.shared.state, type == .verifyReceiptError {
            alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.refreshToRetry, style: .default) { [weak self] _ in
                self?.trackUpgradeErrorAction(errorAction: ErrorAction.refreshToRetry)
                self?.refreshTime = CFAbsoluteTimeGetCurrent()
                CourseUpgradeHandler.shared.reverifyPayment()
            }
        }

        if case .complete = CourseUpgradeHandler.shared.state, completion != nil {
            alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.refreshToRetry, style: .default) {[weak self] _ in
                self?.trackUpgradeErrorAction(errorAction: ErrorAction.refreshToRetry)
                self?.refreshTime = CFAbsoluteTimeGetCurrent()
                self?.showLoader()
                self?.completion?()
                self?.completion = nil
            }
        }

        alertController.addButton(withTitle: Strings.CourseUpgrade.failureAlertGetHelp) { [weak self] _ in
            self?.trackUpgradeErrorAction(errorAction: ErrorAction.emailSupport)
            self?.launchEmailComposer(errorMessage: "Error: \(CourseUpgradeHandler.shared.formattedError)")
        }

        alertController.addButton(withTitle: Strings.close, style: .default) { [weak self] _ in
            self?.trackUpgradeErrorAction(errorAction: ErrorAction.close)
            
            if self?.unlockController.isVisible == true {
                self?.unlockController.removeView() {
                    self?.hideAlertAction()
                }
            }
            else {
                self?.hideAlertAction()
            }
        }
    }
    
    func showLoader() {
        if !unlockController.isVisible {
            unlockController.showView()
        }
    }
    
    func removeLoader(success: Bool? = false, removeView: Bool? = false, completion: (()-> ())? = nil) {
        self.completion = completion
        if success == true {
            courseUpgradeModel = nil
        }

        if unlockController.isVisible, removeView == true {
            unlockController.removeView() { [weak self] in
                self?.courseUpgradeModel = nil
                if success == true {
                    self?.showSuccess()
                } else {
                    self?.showError()
                }
            }
        } else if success == false {
            showError()
        }
    }
    
    private func trackUpgradeErrorAction(errorAction: ErrorAction) {
        environment?.analytics.trackCourseUpgradeErrorAction(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, errorAction: errorAction.rawValue, upgradeError: CourseUpgradeHandler.shared.formattedError)
    }

    private func hideAlertAction() {
        delegate?.hideAlertAction()
        clearData()
    }
}

extension CourseUpgradeHelper: MFMailComposeViewControllerDelegate {
    fileprivate func launchEmailComposer(errorMessage: String) {
        guard let controller = UIApplication.shared.topMostController() else { return }

        if !MFMailComposeViewController.canSendMail() {
            guard let supportEmail = OEXRouter.shared().environment.config.feedbackEmailAddress() else { return }
            UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.emailNotSetupTitle, message: Strings.CourseUpgrade.emailNotSetupMessage(email: supportEmail), onViewController: controller)
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
        controller.dismiss(animated: true) { [weak self] in
            if self?.unlockController.isVisible == true {
                self?.unlockController.removeView() {
                    self?.hideAlertAction()
                }
            }
            else {
                self?.hideAlertAction()
            }
        }
    }
}
