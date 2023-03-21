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
#import "OEXRegistrationStyles.h"
#import "OEXTextStyle.h"

@interface OEXExternalRegistrationOptionsView ()

@property (strong, nonatomic) ExternalAuthOptionsView* authOptionsView;
@property (strong, nonatomic) OEXRegistrationStyles* styles;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicator;

@end

@implementation OEXExternalRegistrationOptionsView

- (id)initWithFrame:(CGRect)frame providers:(NSArray *)providers {
    self = [super initWithFrame:frame];
    if(self != nil) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.styles = [[OEXRegistrationStyles alloc] init];
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        self.activityIndicator.hidden = YES;
        __weak __typeof(self) owner = self;
        self.authOptionsView = [[ExternalAuthOptionsView alloc] initWithFrame:self.bounds providers:providers type:ExternalAuthOptionsTypeRegister accessibilityLabel:@"" tapAction:^(id<OEXExternalAuthProvider> provider) {
            [owner choseProvider:provider];
        }];
        [self.authOptionsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo([NSNumber numberWithFloat:self.authOptionsView.height]);
        }];
        self.authOptionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addSubviews];
    }
    return self;
}

-(void)addSubviews{
    [self addSubview:self.activityIndicator];
    [self addSubview:self.authOptionsView];
}

- (void)updateConstraints {
    
    __weak typeof(self) weakSelf = self;
    
    [self.authOptionsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.mas_top).offset(weakSelf.styles.headingPromptMarginTop);
        make.leading.equalTo(weakSelf.mas_leading);
        make.trailing.equalTo(weakSelf.mas_trailing);
        make.bottom.equalTo(weakSelf.mas_bottom);
    }];
    
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

- (CGFloat)heightForAuthView {
    return self.authOptionsView.height;
}

@end
