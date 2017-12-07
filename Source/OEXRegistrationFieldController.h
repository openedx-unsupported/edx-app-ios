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

@property (readonly, assign, nonatomic) BOOL hasValue;
@property (readonly, assign, nonatomic) BOOL isValidInput;
@property (strong, nonatomic, readonly) OEXRegistrationFormField* field;

// The actual entry field. This doesn't make sense for every subclass
// so those can return null
@property (readonly, nonatomic, nullable) UIView* accessibleInputField;

/// id should be a JSON safe type.
- (id)currentValue;
- (void)setValue:(id)value;

- (void)handleError:(nullable NSString*)errorMsg;

@end

NS_ASSUME_NONNULL_END
