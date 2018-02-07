//
//  OEXRegistrationFieldEmailViewTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "edX-Swift.h"

@interface OEXRegistrationFieldEmailViewTests : XCTestCase

@end

@implementation OEXRegistrationFieldEmailViewTests
- (void)testAutocorrect {
    
    NSDictionary *dict = @{
                           @"defaultValue" : @"",
                           @"errorMessages" : @{
                                   },
                           @"instructions" : @"This is what you will use to login.",
                           @"label" : @"Email",
                           @"name" : @"email",
                           @"placeholder" : @"username@domain.com",
                           @"required" : @"1",
                           @"restrictions" : @{
                                   @"max_length" : @"254",
                                   @"min_length" : @"3",
                                   },
                           @"supplementalLink" : @"",
                           @"supplementalText" : @"",
                           @"type" : @"email"
                        };
    
    OEXRegistrationFormField *formField = [[OEXRegistrationFormField alloc] initWithDictionary:dict];
    RegistrationFormFieldView* view = [[RegistrationFormFieldView alloc] initWith:formField];
    XCTAssertEqual(view.textInputField.autocorrectionType, UITextAutocorrectionTypeNo);
    
}
@end
