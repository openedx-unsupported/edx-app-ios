//
//  OEXRegistrationFieldController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;
#import "OEXRegistrationFormField.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OEXRegistrationFieldController <NSObject>

@property (readonly, nonatomic) UIView* view;

/// id should be a JSON safe type.
- (id)currentValue;
- (void)takeValue:(id)value;

- (BOOL)hasValue;

- (OEXRegistrationFormField*)field;

- (void)handleError:(nullable NSString*)errorMsg;

- (BOOL)isValidInput;

@end

NS_ASSUME_NONNULL_END
