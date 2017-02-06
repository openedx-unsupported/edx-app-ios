//
//  RatingViewController.swift
//  edX
//
//  Created by Danial Zahid on 1/23/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import MessageUI

class RatingViewController: UIViewController, RatingContainerDelegate {

    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, OEXStylesProvider, OEXConfigProvider>
    
    let environment : Environment
    let ratingContainerView : RatingContainerView
    var selectedRating : Int?
    
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupConstraints() {
        ratingContainerView.snp_remakeConstraints { (make) in
            make.centerX.equalTo(view.snp_centerX)
            make.centerY.equalTo(view.snp_centerY)
            make.width.equalTo(275)
        }
    }
    
    //MARK: - RatingContainerDelegate methods
    
    func didSelectRating(rating: CGFloat) {
        selectedRating = Int(rating)
        switch rating {
        case 1...3:
            ratingContainerView.hidden = true
            negativeRatingReceived()
            break
        case 4...5:
            ratingContainerView.hidden = true
            positiveRatingReceived()
            break
        default:
            break
        }
    }
    
    func closeButtonPressed() {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    //MARK: - Positive Rating methods
    func positiveRatingReceived() {
        let alertController = UIAlertController().showAlertWithTitle(Strings.AppReview.rateTheApp, message: Strings.AppReview.positiveReviewMessage,cancelButtonTitle: nil, onViewController: self)
        alertController.addButtonWithTitle(Strings.AppReview.noThanks) { (action) in
            self.saveAppRating()
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        alertController.addButtonWithTitle(Strings.AppReview.askMeLater) { (action) in
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        alertController.addButtonWithTitle(Strings.AppReview.rateTheApp) { (action) in
            self.saveAppRating()
            self.sendUserToAppStore()
            self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    func sendUserToAppStore() {
        guard let url = NSURL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=945480667&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software") else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    //MARK: - Negative Rating methods
    func negativeRatingReceived() {
        let alertController = UIAlertController().showAlertWithTitle(Strings.AppReview.sendFeedback, message: Strings.AppReview.helpUsImprove,cancelButtonTitle: nil, onViewController: self)
        alertController.addButtonWithTitle(Strings.AppReview.maybeLater) { (action) in
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        alertController.addButtonWithTitle(Strings.AppReview.sendFeedback) { (action) in
            self.saveAppRating()
            self.launchEmailComposer()
        }
        environment.interface
    }
    
    //MARK: - Persistence methods
    func saveAppRating() {
        guard let rating = selectedRating else { return }
        environment.interface?.saveAppRating(rating)
        environment.interface?.saveAppVersionWhenLastRated(nil)
    }
}

extension RatingViewController : MFMailComposeViewControllerDelegate {
    
    static func supportEmailMessageTemplate() -> String {
        let osVersionText = Strings.SubmitFeedback.osVersion(version: UIDevice.currentDevice().systemVersion)
        let appVersionText = Strings.SubmitFeedback.appVersion(version: NSBundle.mainBundle().oex_shortVersionString(), build: NSBundle.mainBundle().oex_buildVersionString())
        let deviceModelText = Strings.SubmitFeedback.deviceModel(model: UIDevice.currentDevice().model)
        let body = ["\n", Strings.SubmitFeedback.marker, osVersionText, appVersionText, deviceModelText].joinWithSeparator("\n")
        return body
    }
    
    func launchEmailComposer() {
        if !MFMailComposeViewController.canSendMail() {
            let alert = UIAlertView(title: Strings.emailAccountNotSetUpTitle,
                                    message: Strings.emailAccountNotSetUpMessage,
                                    delegate: nil,
                                    cancelButtonTitle: Strings.ok)
            alert.show()
        } else {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.navigationBar.tintColor = OEXStyles.sharedStyles().navigationItemTintColor()
            mail.setSubject(Strings.SubmitFeedback.messageSubject)
            
            mail.setMessageBody(RatingViewController.supportEmailMessageTemplate(), isHTML: false)
            if let fbAddress = environment.config.feedbackEmailAddress() {
                mail.setToRecipients([fbAddress])
            }
            presentViewController(mail, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        self.dismissViewControllerAnimated(false, completion: nil)
    }
}
