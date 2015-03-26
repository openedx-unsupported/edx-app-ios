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

static NSString* const textAreaBackgoundImage = @"bt_grey_default.png";

@interface OEXRegistrationFieldTextAreaView ()
{
    OEXRegistrationFieldWrapperView* registrationWrapper;
}
@end

@implementation OEXRegistrationFieldTextAreaView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        inputView = [[OEXPlaceholderTextView alloc] initWithFrame:CGRectZero];
        inputView.textContainer.lineFragmentPadding = 0;
        inputView.textContainerInset = UIEdgeInsetsMake(5, 10, 5, 10);
        [inputView setFont:[UIFont fontWithName:@"OpenSans" size:13.f]];
        [inputView setTextColor:[UIColor colorWithRed:0.275 green:0.29 blue:0.314 alpha:0.9]];
        [inputView setPlaceholderTextColor:[UIColor colorWithRed:0.675 green:0.69 blue:0.614 alpha:0.9]];
        [inputView.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
        [inputView.layer setBorderWidth:1.0];
        inputView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        //The rounded corner part, where you specify your view's corner radius:
        inputView.layer.cornerRadius = 5;
        inputView.clipsToBounds = YES;
        [self addSubview:inputView];
        registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:registrationWrapper];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat offset = 0;
    CGFloat paddingHorizontal = 20;
    CGFloat bottomPadding = 10;
    CGFloat frameWidth = self.bounds.size.width - 2 * paddingHorizontal;
    [inputView setFrame:CGRectMake(paddingHorizontal, offset, frameWidth, 100)];
    [inputView setPlaceholder:self.placeholder];
    offset = offset + 100;
    [registrationWrapper setRegistrationErrorMessage:self.errorMessage andInstructionMessage:self.instructionMessage];
    [registrationWrapper setNeedsLayout];
    [registrationWrapper layoutIfNeeded];
    [registrationWrapper setFrame:CGRectMake(0, offset, self.bounds.size.width, registrationWrapper.frame.size.height)];
    if([self.errorMessage length] > 0 || [self.instructionMessage length] > 0) {
        offset = offset + registrationWrapper.frame.size.height;
    }
    CGRect frame = self.frame;
    frame.size.height = offset + bottomPadding;
    self.frame = frame;
}

- (void)takeValue:(NSString*)value {
    inputView.text = value;
}

- (NSString*)currentValue {
    return inputView.text;
}

- (void)clearError {
    self.errorMessage = nil;
}

@end
