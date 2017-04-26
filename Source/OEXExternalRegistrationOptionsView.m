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
        self.signUpHeading.attributedText = [self.styles.headingMessagePromptStyle attributedStringWithText:[Strings registrationRegisterPrompt]];
        self.signUpHeading.isAccessibilityElement = NO;
        
        [self addSubview:self.signUpHeading];
        
        self.emailSuggestion = [[UILabel alloc] initWithFrame:CGRectZero];
        self.emailSuggestion.attributedText = [self.styles.headingMessagePromptStyle attributedStringWithText:[Strings registrationRegisterAlternatePrompt]];
        [self addSubview:self.emailSuggestion];
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
        make.leading.equalTo(self.mas_leading);
        make.bottom.equalTo(self.mas_bottom).offset(-self.styles.headingPromptMarginBottom);
    }];
    
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
