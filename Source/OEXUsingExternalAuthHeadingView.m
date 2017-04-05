//
//  OEXUsingExternalAuthHeadingView.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXUsingExternalAuthHeadingView.h"

#import "edX-Swift.h"

#import "NSAttributedString+OEXFormatting.h"
#import "OEXRegistrationStyles.h"
#import "OEXTextStyle.h"

#import <Masonry/Masonry.h>

static const CGFloat OEXUsingExternalAuthCheckMargin = 8;
static const UIEdgeInsets OEXUsingExternalAuthMessageInsets = {.top = 10, .left = 10, .bottom = 10, .right = 15};

@interface OEXUsingExternalAuthHeadingView ()

@property (strong, nonatomic) UIView* box;
@property (strong, nonatomic) UILabel* messageLabel;
@property (strong, nonatomic) UIImageView* checkmarkView;
@property (strong, nonatomic) UILabel* completionLabel;

@property (strong, nonatomic) OEXRegistrationStyles* styles;

@end

@implementation OEXUsingExternalAuthHeadingView

- (id)initWithFrame:(CGRect)frame serviceName:(NSString *)serviceName {
    self = [super initWithFrame:frame];
    if(self != nil) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.styles = [[OEXRegistrationStyles alloc] init];
        
        self.box = [[UIView alloc] initWithFrame:CGRectZero];
        self.box.layer.borderWidth = 1;
        self.box.layer.borderColor = [UIColor darkGrayColor].CGColor; // TODO
        [self addSubview:self.box];
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.attributedText = [self messageTextWithProvider:serviceName];
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:self.messageLabel];
        
        self.checkmarkView = [[UIImageView alloc] initWithImage:[self checkmarkImage]];
        [self addSubview:self.checkmarkView];
        [self.checkmarkView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        self.completionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.completionLabel.attributedText = [self.styles.headingMessagePromptStyle attributedStringWithText:[Strings completeRegistrationPrompt]];
        [self addSubview:self.completionLabel];
        

    }
    return self;
}

- (void)updateConstraints {
    [self.box mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_top).offset(self.styles.headingPromptMarginTop);
        make.leading.equalTo(self.mas_leading);
        make.trailing.equalTo(self.mas_trailing);
    }];
    
    [self.checkmarkView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.box.mas_centerY);
        make.leading.equalTo(self.box.mas_leading).offset(OEXUsingExternalAuthCheckMargin);
    }];
    
    [self.messageLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.box.mas_top).offset(OEXUsingExternalAuthMessageInsets.top);
        make.bottom.equalTo(self.box.mas_bottom).offset(-OEXUsingExternalAuthMessageInsets.bottom);
        make.leading.equalTo(self.checkmarkView.mas_trailing).offset(OEXUsingExternalAuthMessageInsets.left);
        make.trailing.equalTo(self.box.mas_trailing).offset(-OEXUsingExternalAuthMessageInsets.right);
    }];
    
    [self.completionLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.box.mas_bottom).offset(self.styles.headingPromptMarginTop);
        make.leading.equalTo(self.mas_leading);
        make.trailing.equalTo(self.mas_trailing);
        make.bottom.equalTo(self.mas_bottom).offset(-self.styles.headingPromptMarginBottom);
    }];
    
    [super updateConstraints];
}

- (UIImage*)checkmarkImage {
    return [UIImage imageNamed:@"check"];
}

- (void)layoutSubviews {
    self.messageLabel.preferredMaxLayoutWidth = self.bounds.size.width - OEXUsingExternalAuthCheckMargin - OEXUsingExternalAuthMessageInsets.left - OEXUsingExternalAuthMessageInsets.right - self.checkmarkView.image.size.width;
    [super layoutSubviews];
}

- (NSAttributedString*)messageTextWithProvider:(NSString*)provider {
    OEXTextStyle* style = self.styles.headingMessageProviderStyle;
    NSString* platform = [[OEXConfig sharedConfig] platformName];
    NSAttributedString*(^template)(NSAttributedString*) = [style applyWithF:^(NSString* service) {
        return [Strings completeRegistrationInfoWithService:service platformName:platform];
    }];
    NSAttributedString* serviceString = [self.styles.headingMessageProviderStyle attributedStringWithText:provider];
    return template(serviceString);
}

@end
