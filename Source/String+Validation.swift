//
//  String+Validation.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 23/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

extension String {
    func isValidEmailAddress() -> Bool {
        // Regular expression to check the email format. 
        // Ref: NSString+OEXValidation.m
        let emailReg: String = ".+@.+\\..+";
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailReg)
        return emailTest.evaluate(with: self)
    }
}
