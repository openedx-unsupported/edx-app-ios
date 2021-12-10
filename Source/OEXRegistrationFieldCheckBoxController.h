//
//  OEXRegistrationFieldCheckBoxController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;

#import "OEXRegistrationFieldController.h"
#import "OEXRegistrationFormField.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationFieldCheckBoxController : NSObject <OEXRegistrationFieldController>
- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field;
@end

extern NSString* const RegistrationMarketingEmailsOptIn;

NS_ASSUME_NONNULL_END
