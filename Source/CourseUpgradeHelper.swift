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
    
    static let courseID = "CourseID"
    static let blockID = "BlockID"
    static let screen = "Screen"
    
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
        case emailSupport = "get help"
        case close = "close"
    }

    private var upgradeModel: CourseUpgradeModel?

    var courseUpgradeModel: CourseUpgradeModel? {
        get {
            return upgradeModel
        }
    }
    
    // These times are being in analytics
    private var startTime: CFTimeInterval?
    private var refreshTime: CFTimeInterval?
    private var paymentVerifyTime: CFTimeInterval?
    
    private var environment: Environment?
    private var pacing: String?
    private var courseID: CourseBlockID?
    private var blockID: CourseBlockID?
    private var screen: CourseUpgradeScreen = .none
    private var coursePrice: String?
        
    private override init() { }
    
    func setupCourse(environment: Environment, pacing: String, courseID: CourseBlockID, blockID: CourseBlockID? = nil, coursePrice: String, screen: CourseUpgradeScreen) {
        self.environment = environment
        self.pacing = pacing
        self.courseID = courseID
        self.blockID = blockID
        self.coursePrice = coursePrice
        self.screen = screen
    }
    
    func clearData() {
        self.environment = nil
        self.pacing = nil
        self.courseID = nil
        self.blockID = nil
        self.coursePrice = nil
        self.screen = .none
    }
    
    func handleCourseUpgrade(state: CompletionState, delegate: CourseUpgradeHelperDelegate? = nil) {
        self.delegate = delegate
        
        switch state {
        case .initial:
            startTime = CFAbsoluteTimeGetCurrent()
            break
        case .payment:
            paymentVerifyTime = CFAbsoluteTimeGetCurrent()
            break
        case .fulfillment:
            let endTime = CFAbsoluteTimeGetCurrent() - (paymentVerifyTime ?? 0)
            environment?.analytics.trackCourseUpgradeTimeToVerifyPayment(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, elapsedTime: endTime.millisecond)
            showLoader()
            break
        case .success(let courseID, let blockID):
            upgradeModel = CourseUpgradeModel(courseID: courseID, blockID: blockID, screen: screen)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: CourseUpgradeCompletionNotification), object: nil))
            break
        case .error(let type, let error):
            environment?.analytics.trackCourseUpgradePaymentError(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, paymentError: error?.localizedDescription ?? "")
            removeLoader(success: false, removeView: type != .verifyReceiptError)
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
        let endTime = CFAbsoluteTimeGetCurrent() - (startTime ?? 0)
        
        environment?.analytics.trackCourseUpgradeDuration(isRefresh: false, courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, elapsedTime: endTime.millisecond)
        
        if let refreshTime = refreshTime {
            let refreshEndTime = CFAbsoluteTimeGetCurrent() - refreshTime
            
            environment?.analytics.trackCourseUpgradeDuration(isRefresh: true, courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, elapsedTime: refreshEndTime.millisecond)
        }
        
        refreshTime = nil
        startTime = nil
        clearData()
    }
    
    func showError() {
        guard let topController = UIApplication.shared.topMostController() else { return }

        let alertController = UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.FailureAlert.alertTitle, message: CourseUpgradeHandler.shared.errorMessage, cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }

        if case .error (let type, _) = CourseUpgradeHandler.shared.state, type == .verifyReceiptError {
            alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.refreshToRetry, style: .default) { [weak self] _ in
                self?.trackUpgradeErrorAction(errorAction: ErrorAction.refreshToRetry.rawValue)
                self?.refreshTime = CFAbsoluteTimeGetCurrent()
                CourseUpgradeHandler.shared.reverifyPayment()
            }
        }

        if case .complete = CourseUpgradeHandler.shared.state, completion != nil {
            alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.refreshToRetry, style: .default) {[weak self] _ in
                self?.trackUpgradeErrorAction(errorAction: ErrorAction.refreshToRetry.rawValue)
                self?.refreshTime = CFAbsoluteTimeGetCurrent()
                self?.showLoader()
                self?.completion?()
                self?.completion = nil
            }
        }

        alertController.addButton(withTitle: Strings.CourseUpgrade.failureAlertGetHelp) { [weak self] _ in
            self?.trackUpgradeErrorAction(errorAction: ErrorAction.emailSupport.rawValue)
            self?.launchEmailComposer(errorMessage: "Error: \(CourseUpgradeHandler.shared.formattedError)")
        }

        alertController.addButton(withTitle: Strings.close, style: .default) { [weak self] _ in
            self?.trackUpgradeErrorAction(errorAction: ErrorAction.close.rawValue)
            
            if self?.unlockController.isVisible == true {
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
    
    func removeLoader(success: Bool? = false, removeView: Bool? = false, completion: (()-> ())? = nil) {
        self.completion = completion
        if success == true {
            upgradeModel = nil
        }

        if unlockController.isVisible, removeView == true {
            unlockController.removeView() { [weak self] in
                self?.upgradeModel = nil
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
    
    private func trackUpgradeErrorAction(errorAction: String) {
        environment?.analytics.trackCourseUpgradeErrorAction(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, errorAction: errorAction)
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
            if self?.unlockController.isVisible == true {
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
