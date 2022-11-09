//
//  ValuePropDetailViewController.swift
//  edX
//
//  Created by Salman on 19/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

enum CourseUpgradeScreen: String {
    case myCourses = "course_enrollment"
    case courseDashboard = "course_dashboard"
    case courseUnit = "course_unit"
    case none
}

class ValuePropDetailViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXStylesProvider & ReachabilityProvider & NetworkManagerProvider & OEXConfigProvider & OEXInterfaceProvider & ServerConfigProvider
    
    private lazy var valuePropTableView: ValuePropMessagesView = {
        let tableView = ValuePropMessagesView()
        tableView.accessibilityIdentifier = "ValuePropDetailViewController:table-view"
        return tableView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = titleStyle.attributedString(withText: Strings.ValueProp.upgrade(courseName: course.name ?? "")).setLineSpacing(4)
        label.accessibilityIdentifier = "ValuePropDetailViewController:title-label"
        return label
    }()
    
    private lazy var upgradeButton: CourseUpgradeButtonView = {
        let upgradeButton = CourseUpgradeButtonView()
        upgradeButton.tapAction = { [weak self] in
            self?.upgradeCourse()
        }
        upgradeButton.accessibilityIdentifier = "ValuePropDetailViewController:upgrade-button"
        return upgradeButton
    }()
    
    private var titleStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .xxLarge, color: OEXStyles.shared().primaryDarkColor())
        style.alignment = .left
        return style
    }()
    
    private let crossButtonSize: CGFloat = 20
    private var isModalDismissable = true
    
    private var coursePrice: String?
    
    private var pacing: String {
        return course.isSelfPaced ? "self" : "instructor"
    }
    
    private lazy var courseUpgradeHelper = CourseUpgradeHelper.shared
    
    private var screen: CourseUpgradeScreen
    private let course: OEXCourse
    private let environment: Environment
    private let blockID: CourseBlockID?
    
    init(screen: CourseUpgradeScreen, course: OEXCourse, blockID: CourseBlockID? = nil, environment: Environment) {
        self.screen = screen
        self.course = course
        self.blockID = blockID
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = environment.styles.neutralWhiteT()
        navigationController?.navigationBar.apply(barTintColor: environment.styles.neutralWhiteT(), tintColor: environment.styles.primaryBaseColor(), clearShadow: true)
        navigationController?.presentationController?.delegate = self
        
        addObserver()
        configureView()
        fetchCoursePrice()
        trackValuePropMessageViewed()
    }

    private func fetchCoursePrice() {
        guard let courseSku = course.sku else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.main.async { [weak self] in
            self?.upgradeButton.startShimeringEffect()
            PaymentManager.shared.productPrice(courseSku) { [weak self] price in
                if let price = price {
                    let endTime = CFAbsoluteTimeGetCurrent() - startTime
                    self?.coursePrice = price
                    self?.trackPriceLoadDuration(elapsedTime: endTime.millisecond)
                    self?.upgradeButton.stopShimmerEffect()
                    self?.upgradeButton.setPrice(price)
                } else {
                    self?.trackLoadError()
                    self?.showCoursePriceErrorAlert()
                }
            }
        }
    }
    
    private func trackValuePropMessageViewed() {
        guard let courseID = course.course_id else { return }
        let paymentsEnabled = (environment.serverConfig.iapConfig?.enabled ?? false) && course.sku != nil
        let iapExperiementEnabled = environment.serverConfig.iapConfig?.experimentEnabled ?? false
        let group = environment.serverConfig.iapConfig?.experimentGroup
        environment.analytics.trackValuePropMessageViewed(courseID: courseID, paymentsEnabled: paymentsEnabled, iapExperiementEnabled: iapExperiementEnabled, group: group, screen: screen)
    }
    
    private func trackPriceLoadDuration(elapsedTime: Int) {
        guard let courseID = course.course_id,
              let coursePrice = coursePrice else { return }
        
        environment.analytics.trackCourseUpgradeTimeToLoadPrice(courseID: courseID, blockID: blockID, pacing: pacing, coursePrice: coursePrice, screen: screen, elapsedTime: elapsedTime)
    }
    
    private func trackLoadError() {
        guard let courseID = course.course_id else { return }
        environment.analytics.trackCourseUpgradeLoadError(courseID: courseID, blockID: blockID, pacing: pacing, screen: screen)
    }

    private func showCoursePriceErrorAlert() {
        guard let topController = UIApplication.shared.topMostController() else { return }

        let alertController = UIAlertController().showAlert(withTitle: Strings.CourseUpgrade.FailureAlert.alertTitle, message: Strings.CourseUpgrade.FailureAlert.priceFetchErrorMessage, cancelButtonTitle: nil, onViewController: topController) { _, _, _ in }


        alertController.addButton(withTitle: Strings.CourseUpgrade.FailureAlert.priceFetchError) { [weak self] _ in
            self?.fetchCoursePrice()
            self?.environment.analytics.trackCourseUpgradeErrorAction(courseID: self?.course.course_id ?? "" , blockID: self?.blockID ?? "", pacing: self?.pacing ?? "", coursePrice: "", screen: self?.screen ?? .none, errorAction: CourseUpgradeHelper.ErrorAction.reloadPrice.rawValue, upgradeError: "price")
        }

        alertController.addButton(withTitle: Strings.cancel, style: .default) { [weak self] _ in
            self?.upgradeButton.stopShimmerEffect()
            self?.upgradeButton.isHidden = true
            self?.environment.analytics.trackCourseUpgradeErrorAction(courseID: self?.course.course_id ?? "" , blockID: self?.blockID ?? "", pacing: self?.pacing ?? "", coursePrice: "", screen: self?.screen ?? .none, errorAction: CourseUpgradeHelper.ErrorAction.close.rawValue, upgradeError: "price")
        }
    }
    
    private func configureView() {
        addSubviews()
        setConstraints()
    }
    
    private func addSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(valuePropTableView)
        view.addSubview(upgradeButton)
        addCloseButton()
    }
    
    private func addObserver() {
        NotificationCenter.default.oex_addObserver(observer: self, name: UIApplication.willEnterForegroundNotification.rawValue) { _, observer, _ in
            observer.enableUserInteraction(enable: true)
        }
    }
    
    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: crossButtonSize), style: .plain, target: nil, action: nil)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "ValuePropDetailView:close-button"
        navigationItem.rightBarButtonItem = closeButton
        
        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func setConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(StandardHorizontalMargin)
            make.trailing.equalTo(view).inset(StandardHorizontalMargin)
            make.top.equalTo(view).offset(StandardVerticalMargin * 5)
        }
        
        valuePropTableView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel).inset(-StandardHorizontalMargin / 2)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(upgradeButton.snp.top).offset(-StandardVerticalMargin)
        }
        
        upgradeButton.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(StandardHorizontalMargin)
            make.trailing.equalTo(view).inset(StandardHorizontalMargin)
            make.bottom.equalTo(safeBottom).inset(StandardVerticalMargin)
            make.height.equalTo(upgradeButton.height)
        }
    }
    
    private func upgradeCourse() {
        guard let courseID = course.course_id,
              let coursePrice = coursePrice else { return }
        
        environment.analytics.trackUpgradeNow(with: courseID, pacing: pacing, screenName: screen, coursePrice: coursePrice)
        
        courseUpgradeHelper.setupHelperData(environment: environment, pacing: pacing, courseID: courseID, blockID: blockID, coursePrice: coursePrice, screen: screen)

        let upgradeHandler = CourseUpgradeHandler(for: course, environment: environment)
        upgradeHandler.upgradeCourse() { [weak self] status in
            self?.enableUserInteraction(enable: false)
            
            switch status {
            case .payment:
                self?.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .payment)
                break
            case .verify:
                self?.upgradeButton.stopAnimating()
                self?.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .fulfillment)
                break
            case .complete:
                self?.enableUserInteraction(enable: true)
                self?.upgradeButton.isHidden = true
                self?.dismiss(animated: true) { [weak self] in
                    self?.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .success(self?.course.course_id ?? "", self?.blockID))
                }
                break
            case .error(let type, let error):
                self?.enableUserInteraction(enable: true)
                self?.upgradeButton.stopAnimating()
                self?.courseUpgradeHelper.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .error(type, error), delegate: type == .verifyReceiptError ? self : nil)
                break
            default:
                break
            }
        }
    }
    
    private func enableUserInteraction(enable: Bool) {
        isModalDismissable = enable
        DispatchQueue.main.async { [weak self] in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enable
            self?.view.isUserInteractionEnabled = enable
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

extension ValuePropDetailViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return isModalDismissable
    }
}

extension ValuePropDetailViewController: CourseUpgradeHelperDelegate {
    func hideAlertAction() {
        dismiss(animated: true, completion: nil)
    }
}
