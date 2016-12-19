//
//  OEXRegistrationFormTextAreaView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldTextAreaView.h"
#import "OEXRegistrationFieldWrapperView.h"
#import "OEXPlaceholderTextView.h"
#import "OEXStyles.h"

static NSString* const textAreaBackgoundImage = @"bt_grey_default.png";

@interface OEXRegistrationFieldTextAreaView ()

@property (strong, nonatomic) OEXRegistrationFieldWrapperView* registrationWrapper;
@property (strong, nonatomic) OEXPlaceholderTextView* textInputView;

@end

@implementation OEXRegistrationFieldTextAreaView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textInputView = [[OEXPlaceholderTextView alloc] initWithFrame:CGRectZero];
        self.textInputView.textContainer.lineFragmentPadding = 0;
        self.textInputView.textContainerInset = UIEdgeInsetsMake(5, 10, 5, 10);
        [self.textInputView setFont:[[OEXStyles sharedStyles] sansSerifOfSize:13.f]];
        [self.textInputView setTextColor:[UIColor colorWithRed:0.275 green:0.29 blue:0.314 alpha:0.9]];
        [self.textInputView setPlaceholderTextColor:[UIColor colorWithRed:0.675 green:0.69 blue:0.614 alpha:0.9]];
        [self.textInputView.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
        [self.textInputView.layer setBorderWidth:1.0];
        self.textInputView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        //The rounded corner part, where you specify your view's corner radius:
        self.textInputView.layer.cornerRadius = 5;
        self.textInputView.clipsToBounds = YES;
        [self addSubview:self.textInputView];
        self.registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:self.registrationWrapper];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat offset = 0;
    CGFloat paddingHorizontal = 20;
    CGFloat bottomPadding = 10;
    CGFloat frameWidth = self.bounds.size.width - 2 * paddingHorizontal;
    [self.textInputView setFrame:CGRectMake(paddingHorizontal, offset, frameWidth, 100)];
    [self.textInputView setPlaceholder:self.placeholder];
    offset = offset + 100;
    [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:self.instructionMessage];
    [self.registrationWrapper setNeedsLayout];
    [self.registrationWrapper layoutIfNeeded];
    [self.registrationWrapper setFrame:CGRectMake(0, offset, self.bounds.size.width, self.registrationWrapper.frame.size.height)];
    if([self.errorMessage length] > 0 || [self.instructionMessage length] > 0) {
        offset = offset + self.registrationWrapper.frame.size.height;
    }
    CGRect frame = self.frame;
    frame.size.height = offset + bottomPadding;
    self.frame = frame;
}

- (void)takeValue:(NSString*)value {
    self.textInputView.text = value;
}

- (NSString*)currentValue {
    return self.textInputView.text;
}

- (void)clearError {
    self.errorMessage = nil;
}

@end
