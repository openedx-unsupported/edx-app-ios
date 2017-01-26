//
//  RatingViewController.swift
//  edX
//
//  Created by Danial Zahid on 1/23/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class RatingViewController: UIViewController {

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

        view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
        view.addSubview(ratingContainerView)
        
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
}
