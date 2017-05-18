//
//  EnrollmentShared.swift
//  edX
//
//  Created by Akiva Leffert on 12/29/15.
//  Copyright © 2015 edX. All rights reserved.
//

@objc class EnrollmentShared : NSObject {

    static let successNotification = "OEXEnrollmentSuccessNotification"
    
    // This is an delay chosen semi-arbitrarily to ensure that any transition animation has completed
    static let overlayMessageDelay : TimeInterval = 0.5

}
