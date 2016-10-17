//
//  OEXRegistrationViewControllerTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXAnalytics.h"
#import "OEXConfig.h"
#import "OEXRegistrationDescription.h"
#import "OEXRegistrationFormField.h"
#import "OEXRegistrationViewController.h"

@interface OEXRegistrationViewControllerTests : XCTestCase

@end

@implementation OEXRegistrationViewControllerTests

- (void)testRegistrationFieldDescriptionParses {

    NSArray* fields = @[[self optionalTestField], [self requiredTestField]];
    NSString* method = @"POST";
    NSString* submitURL = @"http://example.com/register";
    OEXRegistrationDescription* description = [[OEXRegistrationDescription alloc] initWithFields:fields method:method submitURL:submitURL];
    OEXRegistrationViewController* controller = [[OEXRegistrationViewController alloc] initWithEnvironment:nil];
    controller.registrationDescription = description;
    
    XCTAssertGreaterThan(controller.registrationDescription.registrationFormFields.count, 1);
}

- (OEXRegistrationFormField*)requiredTestField {
    OEXMutableRegistrationFormField* field = [[OEXMutableRegistrationFormField alloc] init];
    field.isRequired = YES;
    return field;
}

- (OEXRegistrationFormField*)optionalTestField {
    OEXMutableRegistrationFormField* field = [[OEXMutableRegistrationFormField alloc] init];
    return field;
}

@end
