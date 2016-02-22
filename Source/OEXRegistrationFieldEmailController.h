//
//  OEXRegistrationFieldEmailController.H
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import UIKit;

#import "OEXRegistrationFieldController.h"
#import "OEXRegistrationFormField.h"
#import "OEXRegistrationFieldEmailView.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationFieldEmailController : NSObject <OEXRegistrationFieldController>

- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field;

@end

NS_ASSUME_NONNULL_END
