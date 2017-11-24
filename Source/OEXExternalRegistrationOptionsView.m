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
        [self addSubview:self.activityIndicator];

        __weak __typeof(self) owner = self;
        self.authOptionsView = [[OEXExternalAuthOptionsView alloc] initWithFrame:self.bounds providers:providers tapAction:^(id<OEXExternalAuthProvider> provider) {
            [owner choseProvider:provider];
        }];
        self.authOptionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.authOptionsView];
        
        self.signUpHeading = [[UILabel alloc] initWithFrame:CGRectZero];
//        self.signUpHeading.attributedText = [self.styles.headingMessagePromptStyle attributedStringWithText:[Strings registrationRegisterPrompt]];
        self.signUpHeading.text = [Strings registrationRegisterPrompt];
        self.signUpHeading.textColor = [[OEXStyles sharedStyles] neutralDark];
        [self.signUpHeading setFont:[[OEXStyles sharedStyles] boldSansSerifOfSize:14.0]];
        self.signUpHeading.isAccessibilityElement = NO;
        
        [self addSubview:self.signUpHeading];
        
        self.emailSuggestion = [[UILabel alloc] initWithFrame:CGRectZero];
//        self.emailSuggestion.attributedText = [self.styles.headingMessagePromptStyle attributedStringWithText:[Strings registrationRegisterAlternatePrompt]];
        self.emailSuggestion.text = [Strings registrationRegisterAlternatePrompt];
        [self.emailSuggestion setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:self.emailSuggestion];
        self.emailSuggestion.textColor = [[OEXStyles sharedStyles] neutralDark];
        [self.emailSuggestion setFont:[[OEXStyles sharedStyles] boldSansSerifOfSize:14.0]];
        _leftSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator3"]];
        _rightSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator3"]];
        
        [self addSubview:_leftSeparator];
        [self addSubview:_rightSeparator];
        
        
    }
    return self;
}

- (void)updateConstraints {
    
    [self.signUpHeading mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_top).offset(self.styles.headingPromptMarginTop);
        make.leading.equalTo(self.mas_leading);
    }];
    [self.authOptionsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.signUpHeading.mas_bottom).offset(self.styles.headingPromptMarginTop);
        make.leading.equalTo(self.mas_leading);
        make.trailing.equalTo(self.mas_trailing);
    }];
    
    [self.emailSuggestion mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.authOptionsView.mas_bottom).offset(self.styles.headingPromptMarginTop);
        make.bottom.equalTo(self.mas_bottom).offset(-self.styles.headingPromptMarginBottom);
        make.centerX.equalTo(self.authOptionsView.mas_centerX);
    }];
    
    [self.leftSeparator mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.signUpHeading.mas_leading);
        make.trailing.equalTo(_emailSuggestion.mas_leading).offset(-8);
        make.height.mas_equalTo(1.0);
        make.centerY.equalTo(self.emailSuggestion.mas_centerY);
    }];
    
    [self.rightSeparator mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.trailing.equalTo(self.mas_trailing);
        make.leading.equalTo(_emailSuggestion.mas_trailing);
        make.height.mas_equalTo(1.0);
        make.centerY.equalTo(self.emailSuggestion.mas_centerY);
        make.width.equalTo(_leftSeparator);
    }];
    [self.emailSuggestion setContentHuggingPriority:999 forAxis:UILayoutConstraintAxisHorizontal];
    [self.leftSeparator setContentCompressionResistancePriority:749 forAxis:UILayoutConstraintAxisHorizontal];
    [self.rightSeparator setContentCompressionResistancePriority:749 forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.authOptionsView);
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
