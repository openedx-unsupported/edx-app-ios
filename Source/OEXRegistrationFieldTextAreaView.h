//
//  OEXRegistrationFormTextAreaView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import UIKit;
#import "OEXRegistrationFormField.h"
NS_ASSUME_NONNULL_BEGIN

@class OEXPlaceholderTextView;

@interface OEXRegistrationFieldTextAreaView : UIView

- (void)takeValue:(NSString*)value;

@property (strong, nonatomic) UILabel* textInputLabel;
@property (readonly, strong, nonatomic) OEXPlaceholderTextView* textInputView;
@property(nonatomic, strong) OEXRegistrationFormField* field;
@property(nonatomic, strong, nullable) NSString* errorMessage;
//@property(nonatomic, strong) NSString* instructionMessage;
//@property(nonatomic, strong) NSString* placeholder;
//@property(nonatomic, assign) BOOL isRequired;
- (void)clearError;
- (NSString*)currentValue;
@end

NS_ASSUME_NONNULL_END
