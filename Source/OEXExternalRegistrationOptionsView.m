//
//  OEXExternalRegistrationOptionsView.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXExternalRegistrationOptionsView.h"
#import <Masonry/Masonry.h>
#import "edX-Swift.h"
#import "NSArray+OEXFunctional.h"
#import "OEXExternalAuthOptionsView.h"
#import "OEXRegistrationStyles.h"
#import "OEXTextStyle.h"

@interface OEXExternalRegistrationOptionsView ()

@property (strong, nonatomic) OEXExternalAuthOptionsView* authOptionsView;
@property (strong, nonatomic) UILabel* signUpHeading;
@property (strong, nonatomic) UILabel* emailSuggestion;
@property (strong, nonatomic) UIImageView* leftSeparator;
@property (strong, nonatomic) UIImageView* rightSeparator;
@property (strong, nonatomic) OEXRegistrationStyles* styles;
@property (strong, nonatomic) OEXTextStyle* labelStyle;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicator;

@end

@implementation OEXExternalRegistrationOptionsView

- (id)initWithFrame:(CGRect)frame providers:(NSArray *)providers {
    self = [super initWithFrame:frame];
    if(self != nil) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.styles = [[OEXRegistrationStyles alloc] init];
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicator.hidden = YES;
        __weak __typeof(self) owner = self;
        self.authOptionsView = [[OEXExternalAuthOptionsView alloc] initWithFrame:self.bounds providers:providers tapAction:^(id<OEXExternalAuthProvider> provider) {
            [owner choseProvider:provider];
        }];
        self.authOptionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.labelStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:[[OEXStyles sharedStyles] neutralDark]];
        self.signUpHeading = [[UILabel alloc] initWithFrame:CGRectZero];
        self.signUpHeading.attributedText = [self.labelStyle attributedStringWithText:[Strings registrationRegisterPrompt]];
        self.signUpHeading.isAccessibilityElement = NO;
        self.emailSuggestion = [[UILabel alloc] initWithFrame:CGRectZero];
        self.emailSuggestion.attributedText = [self.labelStyle attributedStringWithText:[Strings registrationRegisterAlternatePrompt]];
        [self.emailSuggestion setTextAlignment:NSTextAlignmentCenter];
        self.leftSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator3"]];
        self.rightSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator3"]];
        
        [self addSubviews];
    }
    return self;
}

-(void)addSubviews{
    [self addSubview:self.activityIndicator];
    [self addSubview:self.authOptionsView];
    [self addSubview:self.signUpHeading];
    [self addSubview:self.emailSuggestion];
    [self addSubview:self.leftSeparator];
    [self addSubview:self.rightSeparator];
}

- (void)updateConstraints {
    
    __weak typeof(self) weakSelf = self;
    
    [self.signUpHeading mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.mas_top).offset(weakSelf.styles.headingPromptMarginTop);
        make.leading.equalTo(weakSelf.mas_leading);
    }];
    [self.authOptionsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.signUpHeading.mas_bottom).offset(weakSelf.styles.headingPromptMarginTop);
        make.leading.equalTo(weakSelf.mas_leading);
        make.trailing.equalTo(weakSelf.mas_trailing);
    }];
    
    [self.emailSuggestion mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.authOptionsView.mas_bottom).offset(weakSelf.styles.headingPromptMarginTop);
        make.bottom.equalTo(weakSelf.mas_bottom).offset(-weakSelf.styles.headingPromptMarginBottom);
        make.centerX.equalTo(weakSelf.authOptionsView.mas_centerX);
    }];
    
    [self.leftSeparator mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.signUpHeading.mas_leading);
        make.trailing.equalTo(weakSelf.emailSuggestion.mas_leading).offset(-8);
        make.height.mas_equalTo(1.0);
        make.centerY.equalTo(weakSelf.emailSuggestion.mas_centerY);
    }];
    
    [self.rightSeparator mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(weakSelf.mas_trailing);
        make.leading.equalTo(_emailSuggestion.mas_trailing);
        make.height.mas_equalTo(1.0);
        make.centerY.equalTo(weakSelf.emailSuggestion.mas_centerY);
        make.width.equalTo(weakSelf.leftSeparator);
    }];
    [self.emailSuggestion setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.leftSeparator setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.rightSeparator setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.authOptionsView);
    }];
    
    [super updateConstraints];
}

- (void)choseProvider:(id<OEXExternalAuthProvider>)provider {
    [self.delegate optionsView:self choseProvider:provider];
}

- (void)beginIndicatingActivity {
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    self.authOptionsView.hidden = YES;
}

- (void)endIndicatingActivity {
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
    self.authOptionsView.hidden = NO;
}

@end
