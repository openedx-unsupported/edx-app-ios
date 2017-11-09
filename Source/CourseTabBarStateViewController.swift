//
//  CourseTabBarStateViewController.swift
//  edX
//
//  Created by Salman on 09/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseTabBarStateViewController: UIViewController {

    public let loadController = LoadStateViewController()
    private let contentView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(contentView)
        contentView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        loadController.setupInController(controller: self, contentView: contentView)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
