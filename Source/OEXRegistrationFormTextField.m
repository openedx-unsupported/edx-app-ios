//
//  OEXRegistrationFormTextField.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFormTextField.h"
#import "OEXRegistrationFieldWrapperView.h"
#import "OEXStyles.h"
#import "OEXTextStyle.h"

@interface OEXRegistrationFormTextField () <UITextFieldDelegate>

@property (strong, nonatomic) OEXRegistrationFieldWrapperView* registrationWrapper;
@property (strong, nonatomic) UIImageView* backgroundView;
@property (nonatomic) OEXTextStyle *placeHolderStyle;

@end

static NSString* const textFieldBackgoundImage = @"bt_grey_default.png";
static NSInteger const textFieldHeight = 40;

@implementation OEXRegistrationFormTextField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textInputView = [[UITextField alloc] initWithFrame:CGRectZero];
        self.textInputView.font = [[OEXStyles sharedStyles] sansSerifOfSize:13.f];
        self.textInputView.textColor = [UIColor colorWithRed:0.275 green:0.29 blue:0.314 alpha:1.0];
        self.textInputView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textInputView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textInputView.delegate = self;
        _placeHolderStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:[[OEXStyles sharedStyles] neutralDark]];
        
        self.backgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.backgroundView.image = [UIImage imageNamed:textFieldBackgoundImage];
        
        [self addSubview:self.backgroundView];
        [self addSubview:self.textInputView];
        
        self.registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:self.registrationWrapper];
        
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat paddingHorizontal = 20;
    CGFloat frameWidth = self.bounds.size.width - 2 * paddingHorizontal;
    NSInteger paddingTop = 0;
    CGFloat offset = paddingTop;
    CGFloat paddingBottom = 10;
    
    self.backgroundView.frame = CGRectMake(paddingHorizontal, paddingTop, frameWidth, textFieldHeight);
    self.textInputView.frame = CGRectInset(self.backgroundView.frame, 10, 10);
    
    [self.textInputView setAttributedPlaceholder:[_placeHolderStyle attributedStringWithText:self.placeholder]];
    self.textInputView.accessibilityHint = self.instructionMessage;
    offset = offset + textFieldHeight;
    [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:self.instructionMessage];
    [self.registrationWrapper setFrame:CGRectMake(0, offset, self.bounds.size.width, self.registrationWrapper.frame.size.height)];
    [self.registrationWrapper setNeedsLayout];
    [self.registrationWrapper layoutIfNeeded];

    if([self.errorMessage length] > 0 || [self.instructionMessage length] > 0) {
        offset = offset + self.registrationWrapper.frame.size.height;
    }
    CGRect frame = self.frame;
    frame.size.height = offset + paddingBottom;
    self.frame = frame;
    
    if (self.fieldType == OEXRegistrationFieldTypeSelect) {
        [self.textInputView setAttributedPlaceholder:[_placeHolderStyle attributedStringWithText:@""]];
    }
    
    [super layoutSubviews];
}

- (void)takeValue:(NSString *)value {
    if(value) {
        self.textInputView.text = value;
    }
}

- (NSString*)currentValue {
    return self.textInputView.text;
}

- (void)clearError {
    self.errorMessage = nil;
}

- (void)setErrorMessage:(NSString*)errorMessage {
    _errorMessage = errorMessage;
    [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:self.instructionMessage];
    [self.registrationWrapper layoutIfNeeded];
    [self setNeedsLayout];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([textField isEqual:self.textInputView] && [textField.text isEqualToString:@""] && string.length > 0) {
        textField.accessibilityLabel = self.placeholder;
    }
    else if([textField isEqual:self.textInputView] && [string isEqualToString:@""] && textField.text.length == 1) {
        textField.accessibilityLabel = nil;
    }
    return YES;
}


@end
