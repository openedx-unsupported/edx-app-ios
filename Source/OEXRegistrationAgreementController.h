//
//  OEXRegistrationAgreementController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;

#import "OEXRegistrationFieldController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationAgreementController : NSObject <OEXRegistrationFieldController>
- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field;
@end

NS_ASSUME_NONNULL_END
