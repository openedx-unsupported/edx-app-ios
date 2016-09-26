//
//  OEXRegistrationFieldValidation.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 03/03/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;

#import "OEXRegistrationFormField.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationFieldValidator : NSObject
/// Returns an error string, or nil if no error
+ (NSString* _Nullable)validateField:(OEXRegistrationFormField*)field withText:(NSString*)currentValue;
@end

NS_ASSUME_NONNULL_END
