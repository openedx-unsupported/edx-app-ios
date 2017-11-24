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
    RegistrationFormFieldView* view = [[RegistrationFormFieldView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    XCTAssertEqual(view.textInputField.autocorrectionType, UITextAutocorrectionTypeNo);
    
}
@end
