//
//  OEXRegistrationFormTextField.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationFormTextField : UIView

@property(nonatomic, strong, nullable) NSString* errorMessage;
@property(nonatomic, strong) NSString* instructionMessage;
@property(nonatomic, strong) NSString* placeholder;

@property (strong, nonatomic) UITextField* textInputView;

- (void)takeValue:(NSString*)value;

- (void)clearError;
- (NSString*)currentValue;

@end

NS_ASSUME_NONNULL_END
