//
//  OEXRegistrationFieldSelectController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;
#import "OEXRegistrationFieldController.h"
#import "OEXRegistrationFormField.h"
#import "OEXRegistrationFieldEmailView.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationFieldSelectController : NSObject <OEXRegistrationFieldController>

- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field;

@end

NS_ASSUME_NONNULL_END
