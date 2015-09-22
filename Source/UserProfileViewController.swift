//
//  UserProfileViewController.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {

    
    var profile: UserProfile!
    
    init(profile: UserProfile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let circleImage = CircleImageView()
        view.addSubview(circleImage)

        circleImage.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(circleImage.snp_height)
            make.width.equalTo(120)
            make.center.equalTo(view)
        }
//        let stackview = OA
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
