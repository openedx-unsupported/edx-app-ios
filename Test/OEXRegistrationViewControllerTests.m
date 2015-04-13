//
//  OEXRegistrationViewControllerTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXRegistrationDescription.h"
#import "OEXRegistrationFormField.h"
#import "OEXRegistrationViewController.h"

@interface OEXRegistrationViewControllerTests : XCTestCase

@end

@implementation OEXRegistrationViewControllerTests

- (void)testRegistrationFieldDescriptionParses {
    // Ensure the form we're shipping with the app is valid JSON with a field
    OEXRegistrationViewController* controller = [[OEXRegistrationViewController alloc] initWithDefaultRegistrationDescription];
    OEXRegistrationDescription* description = [controller t_registrationFormDescription];
    XCTAssertGreaterThan(description.registrationFormFields.count, 1);
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

- (void)testShowOptionalFields {
    NSArray* fields = @[[self optionalTestField], [self requiredTestField]];
    NSString* method = @"POST";
    NSString* submitURL = @"http://example.com/register";
    OEXRegistrationDescription* description = [[OEXRegistrationDescription alloc] initWithFields:fields method:method submitURL:submitURL];
    OEXRegistrationViewController* controller = [[OEXRegistrationViewController alloc] initWithRegistrationDescription:description];
    (void)controller.view; // force view to load
    XCTAssertEqual([controller t_visibleFieldCount], 1);
    [controller t_toggleOptionalFields];
    XCTAssertEqual([controller t_visibleFieldCount], 2);
}

@end
