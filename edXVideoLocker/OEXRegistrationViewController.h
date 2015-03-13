//
//  OEXRegistrationViewController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXRegistrationDescription;

@interface OEXRegistrationViewController : UIViewController

- (id)initWithRegistrationDescription:(OEXRegistrationDescription*)description NS_DESIGNATED_INITIALIZER;
- (id)initWithDefaultRegistrationDescription;

@end


// Only use from within tests
@interface OEXRegistrationViewController (Testing)
- (OEXRegistrationDescription*)t_registrationFormDescription;
- (NSUInteger)t_visibleFieldCount;
- (void)t_toggleOptionalFields;
@end