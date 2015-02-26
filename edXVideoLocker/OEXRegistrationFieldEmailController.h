//
//  OEXRegistrationFieldEmailController.H
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXRegistrationFieldController.h"
#import "OEXRegistrationFormField.h"
#import "OEXRegistrationFieldEmailView.h"

@interface OEXRegistrationFieldEmailController:NSObject<OEXRegistrationFieldController>

-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field;

@end
