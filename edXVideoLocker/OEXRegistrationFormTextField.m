//
//  OEXRegistrationFormTextField.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFormTextField.h"
#import "OEXRegistrationFieldWrapperView.h"

@interface OEXRegistrationFormTextField ()

@property (strong, nonatomic) OEXRegistrationFieldWrapperView* registrationWrapper;

@end

static NSString* const textFieldBackgoundImage = @"bt_grey_default.png";
static NSInteger const textFieldHeight = 40;
@implementation OEXRegistrationFormTextField
-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.inputView = [[UITextField alloc] initWithFrame:CGRectZero];
        self.inputView.font = [UIFont fontWithName:@"OpenSans" size:13.f];
        self.inputView.textColor = [UIColor colorWithRed:0.275 green:0.29 blue:0.314 alpha:1.0];
        self.inputView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.inputView.autocorrectionType = UITextAutocorrectionTypeNo;
        [self.inputView setBackground:[UIImage imageNamed:textFieldBackgoundImage]];

        UIView* paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
        self.inputView.leftView = paddingView;
        self.inputView.leftViewMode = UITextFieldViewModeAlways;
        [self addSubview:self.inputView];
        self.registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:self.registrationWrapper];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGFloat paddingHorizontal = 20;
    CGFloat frameWidth = self.bounds.size.width - 2 * paddingHorizontal;
    NSInteger paddingTop = 0;
    CGFloat offset = paddingTop;
    CGFloat paddingBottom = 10;
    [self.inputView setFrame:CGRectMake(paddingHorizontal, paddingTop, frameWidth, textFieldHeight)];
    [self.inputView setPlaceholder:self.placeholder];
    offset = offset + textFieldHeight;
    [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage andInstructionMessage:self.instructionMessage];
    [self.registrationWrapper setFrame:CGRectMake(0, offset, self.bounds.size.width, self.registrationWrapper.frame.size.height)];
    [self.registrationWrapper setNeedsLayout];
    [self.registrationWrapper layoutIfNeeded];

    if([self.errorMessage length] > 0 || [self.instructionMessage length] > 0) {
        offset = offset + self.registrationWrapper.frame.size.height;
    }
    CGRect frame = self.frame;
    frame.size.height = offset + paddingBottom;
    self.frame = frame;
}

-(NSString*)currentValue {
    return self.inputView.text;
}

-(void)clearError {
    self.errorMessage = nil;
}

-(void)setErrorMessage:(NSString*)errorMessage {
    _errorMessage = errorMessage;
    [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage andInstructionMessage:self.instructionMessage];
    [self.registrationWrapper layoutIfNeeded];
    [self setNeedsLayout];
}

@end
