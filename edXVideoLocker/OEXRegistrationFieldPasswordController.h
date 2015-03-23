//
//  OEXRegistrationFieldPasswordController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXRegistrationFieldController.h"
#import "OEXRegistrationFormField.h"
@interface OEXRegistrationFieldPasswordController :  NSObject <OEXRegistrationFieldController>

- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field;

@end
