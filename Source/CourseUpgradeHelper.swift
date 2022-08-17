//
//  CourseUpgradeHelper.swift
//  edX
//
//  Created by Muhammad Umer on 16/12/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
import MessageUI
import KeychainSwift

let CourseUpgradeCompletionNotification = "CourseUpgradeCompletionNotification"
private let IAPKeychainKey = "CourseUpgradeIAPKeyChainKey"

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
    private lazy var keychain = KeychainSwift()

    enum CompletionState {
        case initial
        case sdn
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
    weak private(set) var upgradeHadler: CourseUpgradeHandler?
        
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
    
    func handleCourseUpgrade(upgradeHadler: CourseUpgradeHandler, state: CompletionState, delegate: CourseUpgradeHelperDelegate? = nil) {
        self.delegate = delegate
        self.upgradeHadler = upgradeHadler
        
        switch state {
        case .initial:
            startTime = CFAbsoluteTimeGetCurrent()
            break
        case .sdn:
            trackSDNanlytics(allowed: true)
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
            if upgradeHadler.upgradeMode == .normal {
                postSuccessNotification()
            }
            else {
                showSilentRefreshAlert()
            }
            break
        case .error(let type, _):
            if type == .paymentError {
                environment?.analytics.trackCourseUpgradePaymentError(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, paymentError: upgradeHadler.formattedError)
            } else if type == .sdnError {
                trackSDNanlytics(allowed: false)
            }

            environment?.analytics.trackCourseUpgradeError(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, upgradeError: upgradeHadler.formattedError)

            removeLoader(success: false, removeView: type != .verifyReceiptError)
            break
        }
    }
    
    private func trackSDNanlytics(allowed: Bool) {
        environment?.analytics.trackSDN(accept: allowed, courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen)
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

        let alertController = UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.FailureAlert.alertTitle, message: upgradeHadler?.errorMessage, cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }

        if case .error (let type, _) = upgradeHadler?.state, type == .verifyReceiptError {
            alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.refreshToRetry, style: .default) { [weak self] _ in
                self?.trackUpgradeErrorAction(errorAction: ErrorAction.refreshToRetry)
                self?.refreshTime = CFAbsoluteTimeGetCurrent()
                self?.upgradeHadler?.reverifyPayment()
            }
        }

        if case .complete = upgradeHadler?.state, completion != nil {
            alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.refreshToRetry, style: .default) {[weak self] _ in
                self?.trackUpgradeErrorAction(errorAction: ErrorAction.refreshToRetry)
                self?.refreshTime = CFAbsoluteTimeGetCurrent()
                self?.showLoader()
                self?.completion?()
                self?.completion = nil
            }
        }

        alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.getHelp) { [weak self] _ in
            self?.trackUpgradeErrorAction(errorAction: ErrorAction.emailSupport)
            self?.launchEmailComposer(errorMessage: "Error: \(self?.upgradeHadler?.formattedError ?? "")")
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

    func showRestorePurchasesAlert() {
        guard let topController = UIApplication.shared.topMostController() else { return }
        let alertController = UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.Restore.alertTitle, message: Strings.CourseUpgrade.Restore.alertMessage, cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }

        alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.getHelp) { [weak self] _ in
            self?.launchEmailComposer(errorMessage: "Error: restore_purchases")
        }

        alertController.addButton(withTitle: Strings.close, style: .default) { _ in
        }
    }
    
    func showLoader(forceShow: Bool = false) {
        if (!unlockController.isVisible && upgradeHadler?.upgradeMode == .normal) || forceShow {
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
        environment?.analytics.trackCourseUpgradeErrorAction(courseID: courseID ?? "", blockID: blockID ?? "", pacing: pacing ?? "", coursePrice: coursePrice ?? "", screen: screen, errorAction: errorAction.rawValue, upgradeError: upgradeHadler?.formattedError ?? "")
    }

    private func hideAlertAction() {
        delegate?.hideAlertAction()
        clearData()
    }

    private func showSilentRefreshAlert() {
        guard let topController = UIApplication.shared.topMostController() else { return }

        let alertController = UIAlertController().alert(withTitle: Strings.CourseUpgrade.SuccessAlert.silentAlertTitle, message: Strings.CourseUpgrade.SuccessAlert.silentAlertMessage, cancelButtonTitle: nil) { _, _, _ in }

        alertController.addButton(withTitle: Strings.CourseUpgrade.SuccessAlert.silentAlertRefresh, style: .default) {[weak self] _ in
            self?.showLoader(forceShow: true)
            self?.popToEnrolledCourses()
        }

        alertController.addButton(withTitle: Strings.CourseUpgrade.SuccessAlert.silentAlertContinue, style: .default) {[weak self] _ in
            self?.resetUpgradeModel()
        }

        topController.present(alertController, animated: true, completion: nil)
    }

    private func popToEnrolledCourses() {
        dismiss { [weak self] in
            guard let topController = UIApplication.shared.topMostController(),
                  let tabController = topController.navigationController?.viewControllers.first(where: {$0 is EnrolledTabBarViewController}) else {
                      self?.postSuccessNotification()
                      return
                  }
            tabController.navigationController?.popToRootViewController(animated: false)
            self?.markCourseContentRefresh()
            self?.postSuccessNotification()
        }
    }

    private func markCourseContentRefresh() {
        guard let course = upgradeHadler?.course else { return }

        let courseQuerier = OEXRouter.shared().environment.dataManager.courseDataManager.querierForCourseWithID(courseID: course.course_id ?? "", environment: OEXRouter.shared().environment)
        courseQuerier.needsRefresh = true
    }

    private func dismiss(completion: @escaping () -> Void) {
        if let rootController = UIApplication.shared.window?.rootViewController, rootController.presentedViewController != nil {
            rootController.dismiss(animated: true) {
                completion()
            }
        }
        else {
            completion()
        }
    }

    private func postSuccessNotification() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: CourseUpgradeCompletionNotification), object: nil))
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


// Handle Keychain
// Save inprogress in-app in the keychain for partially fulfilled IAP
extension CourseUpgradeHelper {

    // Test Func for deleting data
    func removekeyChain() {
        keychain.delete(IAPKeychainKey)
    }

    func saveIAPInKeychain(_ sku: String?) {
        guard let sku = sku,
              let userName = OEXSession.shared()?.currentUser?.username, !sku.isEmpty else { return }

        var purchases = savedIAPSKUsFromKeychain()
        let existingPurchases = purchases[userName]?.filter { $0.identifier == sku}

        if existingPurchases?.isEmpty ?? true {
            let purchase = InappPurchase(with: sku, status: false)
            if purchases[userName] == nil {
                purchases[userName] = [purchase]
            }
            else {
                purchases[userName]?.append(purchase)
            }
        }

        if let data = try? NSKeyedArchiver.archivedData(withRootObject: purchases, requiringSecureCoding: false) {
            keychain.set(data, forKey: IAPKeychainKey)
        }
    }

    func removeIAPSKUFromKeychain(_ sku: String?) {
        guard let sku = sku,
              let userName = OEXSession.shared()?.currentUser?.username, !sku.isEmpty else { return }

        var purchases = savedIAPSKUsFromKeychain()
        let userPurchases = purchases[userName]?.filter { $0.identifier == sku && $0.status == false}

        if !(userPurchases?.isEmpty ?? true) {
            purchases[userName]?.removeAll(where: { $0.identifier == sku})
        }
        
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: purchases, requiringSecureCoding: false) {
            keychain.set(data, forKey: IAPKeychainKey)
        }
    }

    func markIAPSKUCompleteInKeychain(_ sku: String?) {
        guard let sku = sku,
              let userName = OEXSession.shared()?.currentUser?.username, !sku.isEmpty else { return }

        var purchases = savedIAPSKUsFromKeychain()
        let userPurchases = purchases[userName] ?? []

        for userPurchase in userPurchases where userPurchase.identifier == sku {
            userPurchase.status = true
        }
        purchases[userName] = userPurchases

        if let data = try? NSKeyedArchiver.archivedData(withRootObject: purchases, requiringSecureCoding: false) {
            keychain.set(data, forKey: IAPKeychainKey)
        }
    }

    private func savedIAPSKUsFromKeychain() -> [String : [InappPurchase]] {
        guard let data = keychain.getData(IAPKeychainKey),
              let purchases = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String : [InappPurchase]]
        else { return [:] }

        return purchases
    }

    func savedUnfinishedIAPSKUsForCurrentUser() -> [String]? {
        guard let userName = OEXSession.shared()?.currentUser?.username else { return nil }

        let purchases = savedIAPSKUsFromKeychain()
        let unfinishedPurchases = purchases[userName]?.filter( { return $0.status == false })

        return unfinishedPurchases?.compactMap { $0.identifier }
    }
}

class InappPurchase: NSObject, NSCoding {
    var status: Bool = false
    var identifier: String = ""

    required init?(coder: NSCoder) {
        identifier = coder.decodeObject(forKey: "identifier") as? String ?? ""
        status = coder.decodeBool(forKey: "status")
    }

    init(with identifier: String, status: Bool) {
        self.status = status
        self.identifier = identifier
    }

    func encode(with coder: NSCoder) {
        coder.encode(identifier, forKey: "identifier")
        coder.encode(status, forKey: "status")
    }
}


