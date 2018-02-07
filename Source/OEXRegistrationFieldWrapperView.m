//
//  OEXRegistrationFieldError.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 23/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldWrapperView.h"
#import "OEXStyles.h"
#import "OEXTextStyle.h"

@interface OEXRegistrationFieldWrapperView ()

@property (strong, nonatomic) UILabel* errorLabel;
@property (strong, nonatomic) UILabel* instructionsLabel;
@property (strong, nonatomic) OEXMutableTextStyle *errorLabelStyle;
@property (strong, nonatomic) OEXMutableTextStyle *instructionsLabelStyle;
@end

@implementation OEXRegistrationFieldWrapperView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.errorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.errorLabel.numberOfLines = 0;
        self.errorLabel.isAccessibilityElement = NO;
        self.errorLabelStyle = [[OEXMutableTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeXXSmall color:[[OEXStyles sharedStyles] errorLight]];
        self.errorLabelStyle.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:self.errorLabel];

        self.instructionsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.instructionsLabel.numberOfLines = 0;
        self.instructionsLabel.isAccessibilityElement = NO;
        [self addSubview:self.instructionsLabel];
        self.instructionsLabelStyle = [[OEXMutableTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeXXSmall color:[[OEXStyles sharedStyles] neutralDark]];
        self.instructionsLabelStyle.lineBreakMode = NSLineBreakByWordWrapping;
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
    if([self.instructionsLabel.text length] > 0) {
        NSDictionary* attributes = @{NSFontAttributeName:self.instructionsLabel.font};
        CGRect rect = [self.instructionsLabel.text boundingRectWithSize:CGSizeMake(frameWidth, CGFLOAT_MAX)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:attributes
                                                          context:nil];
        [self.instructionsLabel setFrame:CGRectMake(paddingHorizontal, offset, frameWidth, rect.size.height)];

        offset = offset + rect.size.height;
    }
    else {
        offset = offset + spacingTextFieldAndLabel;
        [self.instructionsLabel setFrame:CGRectZero];
    }
    CGRect frame = self.frame;
    frame.size.height = offset + paddingBottom;
    self.frame = frame;
}

- (void)setRegistrationErrorMessage:(NSString*)errorMessage instructionMessage:(NSString*)instructionMessage {
    self.errorLabel.attributedText = [self.errorLabelStyle attributedStringWithText:errorMessage];
    self.instructionsLabel.attributedText = [self.instructionsLabelStyle attributedStringWithText:instructionMessage];
    [self.errorLabel sizeToFit];
    [self.instructionsLabel sizeToFit];
    [self setNeedsLayout];
}

@end
