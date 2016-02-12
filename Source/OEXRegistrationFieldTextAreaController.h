//
//  OEXRegistrationFieldTextAreaController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;

#import "OEXRegistrationFieldController.h"
#import "OEXRegistrationFormField.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationFieldTextAreaController : NSObject <OEXRegistrationFieldController>
- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field;
@end

NS_ASSUME_NONNULL_END
