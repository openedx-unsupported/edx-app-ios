//
//  OEXRegistrationFieldError.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 23/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldWrapperView.h"
#import "OEXStyles.h"

@interface OEXRegistrationFieldWrapperView ()

@property (strong, nonatomic) UILabel* errorLabel;
@property (strong, nonatomic) UILabel* instructionLabel;

@end

@implementation OEXRegistrationFieldWrapperView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.errorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.errorLabel.numberOfLines = 0;
        self.errorLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.errorLabel.font = [[OEXStyles sharedStyles] sansSerifOfSize:10.f];
        self.errorLabel.textColor = [UIColor redColor];
        [self addSubview:self.errorLabel];

        self.instructionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.instructionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.instructionLabel.numberOfLines = 0;
        self.instructionLabel.font = [[OEXStyles sharedStyles] sansSerifOfSize:10.f];
        self.instructionLabel.isAccessibilityElement = NO;
        [self addSubview:self.instructionLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat paddingHorizontal = 20;
    CGFloat frameWidth = self.bounds.size.width - 2 * paddingHorizontal;
    NSInteger paddingTop = 0;
    NSInteger spacingTextFieldAndLabel = 3;
    CGFloat offset = paddingTop;
    CGFloat paddingBottom = 0;
    offset = offset;
    if([self.errorLabel.text length] > 0) {
        offset = offset + spacingTextFieldAndLabel;
        NSDictionary* attributes = @{NSFontAttributeName:self.errorLabel.font};
        CGRect rect = [self.errorLabel.text boundingRectWithSize:CGSizeMake(frameWidth, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:attributes
                                                    context:nil];
        [self.errorLabel setFrame:CGRectMake(paddingHorizontal, offset, frameWidth, rect.size.height)];
        offset = offset + rect.size.height;
    }
    else {
        offset = offset + spacingTextFieldAndLabel;
        [self.errorLabel setFrame:CGRectZero];
    }
    if([self.instructionLabel.text length] > 0) {
        NSDictionary* attributes = @{NSFontAttributeName:self.instructionLabel.font};
        CGRect rect = [self.instructionLabel.text boundingRectWithSize:CGSizeMake(frameWidth, CGFLOAT_MAX)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:attributes
                                                          context:nil];
        [self.instructionLabel setFrame:CGRectMake(paddingHorizontal, offset, frameWidth, rect.size.height)];

        offset = offset + rect.size.height;
    }
    else {
        offset = offset + spacingTextFieldAndLabel;
        [self.instructionLabel setFrame:CGRectZero];
    }
    CGRect frame = self.frame;
    frame.size.height = offset + paddingBottom;
    self.frame = frame;
}

- (void)setRegistrationErrorMessage:(NSString*)errorMessage instructionMessage:(NSString*)instructionMessage {
    self.errorLabel.text = errorMessage;
    self.errorLabel.isAccessibilityElement = NO;
    self.instructionLabel.text = instructionMessage;
    [self setNeedsLayout];
}

@end
