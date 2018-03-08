//
//  CourseDashboardLoadStateViewController.swift
//  edX
//
//  Created by Salman on 09/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseDashboardLoadStateViewController: UIViewController {

    typealias Environment = OEXStylesProvider
    
    public let loadController = LoadStateViewController()
    private let contentView = UIView()
    private let environment: Environment
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(contentView)
        contentView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
        loadController.setupInController(controller: self, contentView: contentView)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
