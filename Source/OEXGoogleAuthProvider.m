//
//  OEXGoogleAuthProvider.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXGoogleAuthProvider.h"

#import "edX-Swift.h"

#import "OEXExternalAuthProviderButton.h"
#import "OEXGoogleSocial.h"
#import "OEXRegisteringUserDetails.h"

@implementation OEXGoogleAuthProvider

- (UIColor*)googleRed {
    return [UIColor colorWithRed:230./255. green:66./255. blue:55./255. alpha:1];
}

- (NSString*)displayName {
    return [Strings google];
}

- (NSString*)backendName {
    return @"google-oauth2";
}

- (OEXExternalAuthProviderButton*)freshAuthButton {
    OEXExternalAuthProviderButton* button = [[OEXExternalAuthProviderButton alloc] initWithFrame:CGRectZero];
    button.provider = self;
    // Because of the '+' the G icon is off center. This accounts for that.
    [button setImageEdgeInsets:UIEdgeInsetsMake(0, 3, 0, -3)];
    [button setImage:[UIImage imageNamed:@"icon_google_white"] forState:UIControlStateNormal];
    [button useBackgroundImageOfColor:[self googleRed]];
    return button;
}

- (void)authorizeServiceFromController:(UIViewController *)controller requestingUserDetails:(BOOL)loadUserDetails withCompletion:(void (^)(NSString *, OEXRegisteringUserDetails *, NSError *))completion {
    [[OEXGoogleSocial sharedInstance] loginFromController:controller withCompletion:^(NSString* token, NSError* error){
        [[OEXGoogleSocial sharedInstance] clearHandler];
        if(error) {
            completion(token, nil, error);
        }
        else {
            if(loadUserDetails) {
                [[OEXGoogleSocial sharedInstance] requestUserProfileInfoWithCompletion:^(GIDProfileData* userInfo) {
                    OEXRegisteringUserDetails* profile = [[OEXRegisteringUserDetails alloc] init];
                    profile.email = userInfo.email;
                    profile.name = userInfo.name;
                    completion(token, profile, error);
                }];
            }
            else {
                completion(token, nil, error);
            }
        }
    }];
}

@end
