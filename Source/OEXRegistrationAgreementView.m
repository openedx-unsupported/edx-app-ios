//
//  OEXRegistrationAgreementView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationAgreementView.h"
#import "OEXRegistrationFieldWrapperView.h"
#import "OEXStyles.h"

@interface OEXRegistrationAgreementView ()
{
    OEXRegistrationFieldWrapperView* registrationWrapper;
}

@property(nonatomic, strong) UIButton* inputView;
@end

@implementation OEXRegistrationAgreementView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.inputView = [[UIButton alloc] initWithFrame:CGRectZero];
        self.inputView.titleLabel.font = [[OEXStyles sharedStyles] sansSerifOfSize:10.f];
        [self.inputView setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        self.inputView.titleLabel.text = self.agreement;
        [self.inputView setUserInteractionEnabled:NO];
        [self addSubview:self.inputView];
        registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:registrationWrapper];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSInteger paddingHorizontal = 40;
    NSInteger frameWidth = self.bounds.size.width - 2 * paddingHorizontal;
    NSInteger paddingTop = 0;
    NSInteger offset = paddingTop;
    NSInteger buttonHeight = 30;
    [self.inputView setTitle:self.agreement forState:UIControlStateNormal];
    [self.inputView setFrame:CGRectMake(paddingHorizontal, paddingTop, frameWidth, buttonHeight)];
    offset = offset + buttonHeight;
    [registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:self.instructionMessage];
    [registrationWrapper setNeedsLayout];
    [registrationWrapper layoutIfNeeded];
    [registrationWrapper setFrame:CGRectMake(0, offset, self.bounds.size.width, registrationWrapper.frame.size.height)];
    if([self.errorMessage length] > 0 || [self.instructionMessage length] > 0) {
        offset = offset + registrationWrapper.frame.size.height;
    }
    CGRect frame = self.frame;
    frame.size.height = offset;
    self.frame = frame;
}

- (BOOL)currentValue {
    // Return true by default
    return YES;
}

- (void)clearError {
    self.errorMessage = nil;
}

@end
