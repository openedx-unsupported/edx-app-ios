//
//  RatingViewController.swift
//  edX
//
//  Created by Danial Zahid on 1/23/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class RatingViewController: UIViewController, RatingContainerDelegate {

    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, OEXStylesProvider>
    
    let environment : Environment
    let ratingContainerView : RatingContainerView
    
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
        let alertController = UIAlertController().showAlertWithTitle("Rate the app", message: "Tell others what you think of the edX app by writing a quick review in the app store",cancelButtonTitle: nil, onViewController: self)
        alertController.addButtonWithTitle("No Thanks") { (action) in
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        alertController.addButtonWithTitle("Ask Me Later") { (action) in
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        alertController.addButtonWithTitle("Rate The App") { (action) in
            self.sendUserToAppStore()
        }
    }
    
    func sendUserToAppStore() {
        guard let url = NSURL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=945480667&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software") else {
            return
        }
        
        UIApplication.sharedApplication().openURL(url)
    }
    
    //MARK: - Negative Rating methods
    func negativeRatingReceived() {
        let alertController = UIAlertController().showAlertWithTitle("Send Feedback?", message: "Help us improve!",cancelButtonTitle: nil, onViewController: self)
        alertController.addButtonWithTitle("Maybe Later") { (action) in
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        alertController.addButtonWithTitle("Send Feedback") { (action) in
            
        }
        environment.interface
    }
}
