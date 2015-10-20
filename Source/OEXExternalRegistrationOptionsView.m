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
#import "OEXExternalAuthProviderButton.h"
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
        
        NSArray* providerButtons = [providers oex_map:^id(id <OEXExternalAuthProvider> provider) {
            OEXExternalAuthProviderButton* button = [provider freshAuthButton];
            [button addTarget:self action:@selector(choseProvider:) forControlEvents:UIControlEventTouchUpInside];
            return button;
        }];
        
        self.authOptionsView = [[OEXExternalAuthOptionsView alloc] initWithFrame:self.bounds optionButtons:providerButtons];
        self.authOptionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.authOptionsView];
        
        self.signUpHeading = [[UILabel alloc] initWithFrame:CGRectZero];
        self.signUpHeading.attributedText = [self.styles.headingMessagePromptStyle attributedStringWithText:[Strings registrationSignUpPrompt]];
        
        [self addSubview:self.signUpHeading];
        
        self.emailSuggestion = [[UILabel alloc] initWithFrame:CGRectZero];
        self.emailSuggestion.attributedText = [self.styles.headingMessagePromptStyle attributedStringWithText:[Strings registrationSignUpAlternatePrompt]];
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
        make.top.equalTo(self.signUpHeading.mas_bottom).offset(self.styles.headingPromptMarginBottom);
        make.leading.equalTo(self.mas_leading);
        make.trailing.equalTo(self.mas_trailing);
        make.height.mas_equalTo(self.styles.externalAuthButtonHeight);
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

- (void)choseProvider:(OEXExternalAuthProviderButton*)button {
    [self.delegate optionsView:self choseProvider:button.provider];
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
