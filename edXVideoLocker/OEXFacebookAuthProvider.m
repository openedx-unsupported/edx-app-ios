//
//  OEXFacebookAuthenticationProvider.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFacebookAuthProvider.h"

#import "OEXExternalAuthProviderButton.h"
#import "OEXFBSocial.h"
#import "OEXRegisteringUserDetails.h"

@implementation OEXFacebookAuthProvider

- (UIColor*)facebookBlue {
    return [UIColor colorWithRed:49./255. green:80./255. blue:178./255. alpha:1];
}

- (NSString*)displayName {
    return OEXLocalizedString(@"FACEBOOK", nil);
}

- (NSString*)backendName {
    return @"facebook";
}

- (OEXExternalAuthProviderButton*)freshAuthButton {
    OEXExternalAuthProviderButton* button = [[OEXExternalAuthProviderButton alloc] initWithFrame:CGRectZero];
    [button setTitle:self.displayName forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"icon_facebook_white"] forState:UIControlStateNormal];
    [button useBackgroundImageOfColor:[self facebookBlue]];
    return button;
}

- (void)authorizeServiceWithCompletion:(void (^)(NSString*, OEXRegisteringUserDetails* userProfile, NSError* error))completion {
    [[OEXFBSocial sharedInstance] login:^(NSString *accessToken, NSError *error) {
        [[OEXFBSocial sharedInstance] clearHandler];
        if(error) {
            completion(accessToken, nil, error);
            return;
        }
        
        [[OEXFBSocial sharedInstance] requestUserProfileInfoWithCompletion:^(NSDictionary *userInfo, NSError *error) {
            // userInfo is a facebook user object
            OEXRegisteringUserDetails* profile = [[OEXRegisteringUserDetails alloc] init];
            profile.email = userInfo[@"email"];
            profile.name = userInfo[@"name"];
            completion(accessToken, profile, error);
        }];
        
    }];
}

@end
