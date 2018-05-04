//
//  RatingViewController.swift
//  edX
//
//  Created by Danial Zahid on 1/23/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import MessageUI

protocol RatingViewControllerDelegate {
    func didDismissRatingViewController()
}

class RatingViewController: UIViewController, RatingContainerDelegate {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & OEXStylesProvider & OEXConfigProvider & OEXAnalyticsProvider
    
    var delegate : RatingViewControllerDelegate?
    
    static let minimumPositiveRating : Int = 4
    static let minimumVersionDifferenceForNegativeRating = 2
    
    let environment : Environment
    let ratingContainerView : RatingContainerView
    var alertController : UIAlertController?
    private var selectedRating : Int?
    
    static func canShowAppReview(environment: Environment) -> Bool {
        guard let _ = environment.config.appReviewURI, environment.interface?.reachable ?? false && environment.config.isAppReviewsEnabled else { return false }
        
        if let appRating = environment.interface?.getSavedAppRating(), let lastVersionForAppReview = environment.interface?.getSavedAppVersionWhenLastRated(){
            let version = Version(version: (Bundle.main.oex_buildVersionString()))
            let savedVersion = Version(version: lastVersionForAppReview)
            let validVersionDiff = version.isNMinorVersionsDiff(otherVersion: savedVersion, minorVersionDiff: minimumVersionDifferenceForNegativeRating)
            
            if appRating >= minimumPositiveRating || !validVersionDiff {
                return false
            }
        }
        return true
    }
    
    init(environment : Environment) {
        self.environment = environment
        ratingContainerView = RatingContainerView(environment: environment)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
        view.addSubview(ratingContainerView)
        
        ratingContainerView.delegate = self
        
        setupConstraints()
        
        view.accessibilityElements = [ratingContainerView.subviews]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackAppReviewScreen()
    }
    
    private func setupConstraints() {
        ratingContainerView.snp.remakeConstraints { make in
            make.centerX.equalTo(view.snp.centerX)
            make.centerY.equalTo(view.snp.centerY)
            make.width.equalTo(275)
        }
    }
    
    //MARK: - RatingContainerDelegate methods
    
    func didSubmitRating(rating: Int) {
        selectedRating = Int(rating)
        ratingContainerView.removeFromSuperview()
        environment.analytics.trackSubmitRating(rating: rating)
        switch rating {
        case 1...3:
            negativeRatingReceived()
            break
        case 4...5:
            positiveRatingReceived()
            break
        default:
            break
        }
    }
    
    func closeButtonPressed() {
        saveAppRating()
        environment.analytics.trackDismissRating()
        dismissViewController()
    }
    
    //MARK: - Positive Rating methods
    private func positiveRatingReceived() {
        alertController = UIAlertController().showAlert(withTitle: Strings.AppReview.rateTheApp, message: Strings.AppReview.positiveReviewMessage,cancelButtonTitle: nil, onViewController: self)
        alertController?.addButton(withTitle: Strings.AppReview.maybeLater) {[weak self] (action) in
            self?.saveAppRating()
            if let rating = self?.selectedRating {
                self?.environment.analytics.trackMaybeLater(rating: rating)
            }
            self?.dismissViewController()
        }
        alertController?.addButton(withTitle: Strings.AppReview.rateTheApp) {[weak self] (action) in
            self?.saveAppRating(rating: self?.selectedRating)
            if let rating = self?.selectedRating {
                self?.environment.analytics.trackRateTheApp(rating: rating)
            }
            self?.sendUserToAppStore()
            self?.dismissViewController()
        }
    }
    
    private func sendUserToAppStore() {
        guard let url = NSURL(string: environment.config.appReviewURI ?? "") else { return }
        if UIApplication.shared.canOpenURL(url as URL) {
            UIApplication.shared.openURL(url as URL)
        }
    }
    
    //MARK: - Negative Rating methods
    private func negativeRatingReceived() {
        alertController = UIAlertController().showAlert(withTitle: Strings.AppReview.sendFeedbackTitle, message: Strings.AppReview.helpUsImprove,cancelButtonTitle: nil, onViewController: self)
        alertController?.addButton(withTitle: Strings.AppReview.maybeLater) {[weak self] (action) in
            self?.saveAppRating()
            if let rating = self?.selectedRating {
                self?.environment.analytics.trackMaybeLater(rating: rating)
            }
            self?.dismissViewController()
        }
        alertController?.addButton(withTitle: Strings.AppReview.sendFeedback) {[weak self] (action) in
            self?.saveAppRating(rating: self?.selectedRating)
            if let rating = self?.selectedRating {
                self?.environment.analytics.trackSendFeedback(rating: rating)
            }
            self?.launchEmailComposer()
        }
    }
    
    //MARK: - Persistence methods
    func saveAppRating(rating: Int? = 0) {
        environment.interface?.saveAppRating(rating: rating ?? 0)
        environment.interface?.saveAppVersionWhenLastRated()
    }
    
    //MARK: - Expose for testcases
    func setRating(rating: Int) {
        ratingContainerView.setRating(rating: rating)
    }
    
    func dismissViewController() {
        dismiss(animated: false) {[weak self] in
            self?.delegate?.didDismissRatingViewController()
        }
    }
}

extension RatingViewController : MFMailComposeViewControllerDelegate {
    
    func launchEmailComposer() {
        if !MFMailComposeViewController.canSendMail() {
            UIAlertController().showAlert(withTitle: Strings.emailAccountNotSetUpTitle, message: Strings.emailAccountNotSetUpMessage, onViewController: self)
            dismissViewController()
        } else {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.navigationBar.tintColor = OEXStyles.shared().navigationItemTintColor()
            mail.setSubject(Strings.AppReview.messageSubject)
            
            mail.setMessageBody(EmailTemplates.supportEmailMessageTemplate(), isHTML: false)
            if let fbAddress = environment.config.feedbackEmailAddress() {
                mail.setToRecipients([fbAddress])
            }
            present(mail, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        dismissViewController()
    }
}
