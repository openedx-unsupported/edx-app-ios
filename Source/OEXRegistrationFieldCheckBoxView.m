//
//  OEXRegistrationFieldCheckBoxView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldCheckBoxView.h"
#import "OEXCheckBoxView.h"
#import "OEXRegistrationFieldWrapperView.h"

@interface OEXRegistrationFieldCheckBoxView ()

@property (nonatomic, strong) OEXCheckBoxView* checkBox;
@property (strong, nonatomic) OEXRegistrationFieldWrapperView* registrationWrapper;
@end

@implementation OEXRegistrationFieldCheckBoxView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.checkBox = [[OEXCheckBoxView alloc] initWithFrame:self.bounds];
        [self.checkBox setLabelText:self.label];
        [self addSubview:self.checkBox];
        self.registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:self.registrationWrapper];
    }
    return self;
}

- (void)setLabel:(NSString*)label {
    _label = label;
    [self.checkBox setLabelText:label];
}

- (void)setValue:(BOOL)value {
    [self.checkBox setSelected:value];
}

- (BOOL)currentValue {
    return [self.checkBox selected];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat offset = 0;
    CGFloat paddingHorizontal = 20;
    CGFloat frameWidth = self.bounds.size.width - 2 * paddingHorizontal;
    [self.checkBox setNeedsDisplay];
    [self.checkBox setFrame:CGRectMake(paddingHorizontal, offset, frameWidth, self.checkBox.frame.size.height)];
    offset = offset + 100;
    [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:self.instructionMessage];
    [self.registrationWrapper setFrame:CGRectMake(0, offset, self.bounds.size.width, self.registrationWrapper.frame.size.height)];
    [self.registrationWrapper setNeedsLayout];
    [self.registrationWrapper layoutIfNeeded];
    if([self.errorMessage length] > 0 || [self.instructionMessage length] > 0) {
        offset = offset + self.registrationWrapper.frame.size.height;
    }
    CGRect frame = self.frame;
    frame.size.height = offset;
    self.frame = frame;
}

- (void)clearError {
    self.errorMessage = nil;
}

@end
