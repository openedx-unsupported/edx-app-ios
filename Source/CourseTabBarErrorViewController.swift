//
//  CourseTabBarErrorViewController.swift
//  edX
//
//  Created by Salman on 02/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseTabBarErrorViewController: UIViewController {

    public let loadController = LoadStateViewController()
    let contentView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(contentView)
        contentView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        view.backgroundColor = UIColor.white
        loadController.setupInController(controller: self, contentView: contentView)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
