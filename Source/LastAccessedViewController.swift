//
//  LastAccessedViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class LastAccessedViewController: ViewTopMessageController {
   
    public class Environment {
        private let interface : OEXInterface?
        private let reachability : Reachability
        private let styles : OEXStyles
        
        public init(interface : OEXInterface?, reachability : Reachability = InternetReachability(), styles : OEXStyles) {
            self.interface = interface
            self.reachability = reachability
            self.styles = styles
        }
    }
    
    public init(environment : Environment) {
        let messageView = CourseOutlineHeaderView(frame: CGRectZero, styles: environment.styles, titleLabelString: OEXLocalizedString("LAST_ACCESSED", nil))
        
        
        super.init(messageView : messageView, active : {
            return true; //TODO: activate when the result is finally here.
        })
    }

}
