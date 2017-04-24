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

    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, OEXStylesProvider, OEXConfigProvider, OEXAnalyticsProvider>
    
    var delegate : RatingViewControllerDelegate?
    
    static let minimumPositiveRating : Int = 4
    static let minimumVersionDifferenceForNegativeRating : Float = 0.2
    
    let environment : Environment
    let ratingContainerView : RatingContainerView
    var alertController : UIAlertController?
    private var selectedRating : Int?
    
    static func canShowAppReview(environment: Environment) -> Bool {
        guard let _ = environment.config.appReviewURI where environment.interface?.reachable ?? false && environment.config.isAppReviewsEnabled else { return false }
        
        if let appRating = environment.interface?.getSavedAppRating(), let lastVersionForAppReview = environment.interface?.getSavedAppVersionWhenLastRated(){
            let versionDiff = (Float(NSBundle.mainBundle().oex_shortVersionString()) ?? 0.0) - (Float(lastVersionForAppReview) ?? 0.0)
            if appRating >= minimumPositiveRating || versionDiff < minimumVersionDifferenceForNegativeRating {
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackAppReviewScreen()
    }
    
    private func setupConstraints() {
        ratingContainerView.snp_remakeConstraints { (make) in
            make.centerX.equalTo(view.snp_centerX)
            make.centerY.equalTo(view.snp_centerY)
            make.width.equalTo(275)
        }
    }
    
    //MARK: - RatingContainerDelegate methods
    
    func didSubmitRating(rating: Int) {
        selectedRating = Int(rating)
        ratingContainerView.removeFromSuperview()
        environment.analytics.trackSubmitRating(rating)
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
        alertController = UIAlertController().showAlertWithTitle(Strings.AppReview.rateTheApp, message: Strings.AppReview.positiveReviewMessage,cancelButtonTitle: nil, onViewController: self)
        alertController?.addButtonWithTitle(Strings.AppReview.maybeLater) {[weak self] (action) in
            self?.saveAppRating()
            if let rating = self?.selectedRating {
                self?.environment.analytics.trackMaybeLater(rating)
            }
            self?.dismissViewController()
        }
        alertController?.addButtonWithTitle(Strings.AppReview.rateTheApp) {[weak self] (action) in
            self?.saveAppRating(self?.selectedRating)
            if let rating = self?.selectedRating {
                self?.environment.analytics.trackRateTheApp(rating)
            }
            self?.sendUserToAppStore()
            self?.dismissViewController()
        }
    }
    
    private func sendUserToAppStore() {
        guard let url = NSURL(string: environment.config.appReviewURI ?? "") else { return }
        if UIApplication.sharedApplication().canOpenURL(url) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    //MARK: - Negative Rating methods
    private func negativeRatingReceived() {
        alertController = UIAlertController().showAlertWithTitle(Strings.AppReview.sendFeedback, message: Strings.AppReview.helpUsImprove,cancelButtonTitle: nil, onViewController: self)
        alertController?.addButtonWithTitle(Strings.AppReview.maybeLater) {[weak self] (action) in
            self?.saveAppRating()
            if let rating = self?.selectedRating {
                self?.environment.analytics.trackMaybeLater(rating)
            }
            self?.dismissViewController()
        }
        alertController?.addButtonWithTitle(Strings.AppReview.sendFeedback) {[weak self] (action) in
            self?.saveAppRating(self?.selectedRating)
            if let rating = self?.selectedRating {
                self?.environment.analytics.trackSendFeedback(rating)
            }
            self?.launchEmailComposer()
        }
    }
    
    //MARK: - Persistence methods
    func saveAppRating(rating: Int? = 0) {
        environment.interface?.saveAppRating(rating ?? 0)
        environment.interface?.saveAppVersionWhenLastRated()
    }
    
    //MARK: - Expose for testcases
    func setRating(rating: Int) {
        ratingContainerView.setRating(rating)
    }
    
    func dismissViewController() {
        dismissViewControllerAnimated(false, completion: nil)
        delegate?.didDismissRatingViewController()
    }
}

extension RatingViewController : MFMailComposeViewControllerDelegate {
    
    func launchEmailComposer() {
        if !MFMailComposeViewController.canSendMail() {
            let alert = UIAlertView(title: Strings.emailAccountNotSetUpTitle,
                                    message: Strings.emailAccountNotSetUpMessage,
                                    delegate: nil,
                                    cancelButtonTitle: Strings.ok)
            alert.show()
            dismissViewController()
        } else {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.navigationBar.tintColor = OEXStyles.sharedStyles().navigationItemTintColor()
            mail.setSubject(Strings.AppReview.messageSubject)
            
            mail.setMessageBody(EmailTemplates.supportEmailMessageTemplate(), isHTML: false)
            if let fbAddress = environment.config.feedbackEmailAddress() {
                mail.setToRecipients([fbAddress])
            }
            presentViewController(mail, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        dismissViewController()
    }
}
