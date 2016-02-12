//
//  OEXRegistrationFieldControllerFactory.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXRegistrationFieldController.h"

NS_ASSUME_NONNULL_BEGIN

@class OEXRegistrationFormField;
@interface OEXRegistrationFieldControllerFactory : NSObject
+ ( id <OEXRegistrationFieldController>)registrationFieldViewController:(OEXRegistrationFormField*)registrationField;

@end

NS_ASSUME_NONNULL_END
