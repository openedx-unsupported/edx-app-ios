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
@property (nonatomic) OEXTextStyle *formFieldLabelStyle;

@end

static NSString* const textFieldBackgoundImage = @"bt_grey_default.png";
static NSInteger const textFieldHeight = 40;
static NSInteger const formFieldLabelHeight = 20;

@implementation OEXRegistrationFormTextField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        // Add Label On Top
        self.textInputLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textInputLabel.isAccessibilityElement = NO;
        
        self.textInputView = [[UITextField alloc] initWithFrame:CGRectZero];
        self.textInputView.font = [[OEXStyles sharedStyles] sansSerifOfSize:13.f];
        self.textInputView.textColor = [UIColor colorWithRed:0.275 green:0.29 blue:0.314 alpha:1.0];
        self.textInputView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textInputView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textInputView.delegate = self;
        _placeHolderStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:[[OEXStyles sharedStyles] neutralDark]];
        
        _formFieldLabelStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:[[OEXStyles sharedStyles] neutralDark]];
        
        self.backgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.backgroundView.image = [UIImage imageNamed:textFieldBackgoundImage];
        
        [self addSubview:self.backgroundView];
        [self addSubview:self.textInputView];
        
        self.registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:self.registrationWrapper];
        [self addSubview:self.textInputLabel];
    }
    return self;
}

- (void)layoutSubviews {
    
    if (_field) {
        CGFloat paddingHorizontal = 20;
        CGFloat frameWidth = self.bounds.size.width - 2 * paddingHorizontal;
        NSInteger paddingTop = 24;
        CGFloat offset = paddingTop;
        CGFloat paddingBottom = 10;
        
        self.textInputLabel.frame = CGRectMake(paddingHorizontal, 0, frameWidth, formFieldLabelHeight);
        self.backgroundView.frame = CGRectMake(paddingHorizontal, paddingTop, frameWidth, textFieldHeight);
        self.textInputView.frame = CGRectInset(self.backgroundView.frame, 10, 10);
        
        //    [self.textInputView setAttributedPlaceholder:[_placeHolderStyle attributedStringWithText:_field.label]];
        if (_field.isRequired){
            self.textInputLabel.attributedText = [_formFieldLabelStyle attributedStringWithText:[NSString stringWithFormat:@"%@ *", _field.label]];
        }
        else{
            self.textInputLabel.attributedText = [_formFieldLabelStyle attributedStringWithText:_field.label];
        }
        self.textInputView.accessibilityHint = _field.instructions;
        offset = offset + textFieldHeight;
        [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:_field.instructions];
        [self.registrationWrapper setFrame:CGRectMake(0, offset, self.bounds.size.width, self.registrationWrapper.frame.size.height)];
        [self.registrationWrapper setNeedsLayout];
        [self.registrationWrapper layoutIfNeeded];
        [self.registrationWrapper layoutSubviews];
        
        if([self.errorMessage length] > 0 || [_field.instructions length] > 0) {
            offset = offset + self.registrationWrapper.frame.size.height;
        }
        CGRect frame = self.frame;
        frame.size.height = offset + paddingBottom;
        self.frame = frame;
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
    [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:_field.instructions];
    [self.registrationWrapper layoutIfNeeded];
    [self setNeedsLayout];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([textField isEqual:self.textInputView] && [textField.text isEqualToString:@""] && string.length > 0) {
        textField.accessibilityLabel = _field.label;
    }
    else if([textField isEqual:self.textInputView] && [string isEqualToString:@""] && textField.text.length == 1) {
        textField.accessibilityLabel = nil;
    }
    return YES;
}


@end
