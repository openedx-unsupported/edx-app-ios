//
//  OEXFacebookAuthenticationProvider.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFacebookAuthProvider.h"

#import "edX-Swift.h"

#import "OEXExternalAuthProviderButton.h"
#import "OEXFBSocial.h"
#import "OEXRegisteringUserDetails.h"

@implementation OEXFacebookAuthProvider

- (UIColor*)facebookBlue {
    return [UIColor colorWithRed:66.0/255. green:103.0/255. blue:178./255. alpha:1];
}

- (NSString*)displayName {
    return [Strings facebook];
}

- (NSString*)backendName {
    return @"facebook";
}

- (OEXExternalAuthProviderButton*)freshAuthButton {
    OEXExternalAuthProviderButton* button = [[OEXExternalAuthProviderButton alloc] initWithFrame:CGRectZero];
    button.provider = self;
    [button setImage:[UIImage imageNamed:@"icon_facebook_white"] forState:UIControlStateNormal];
    [button useBackgroundImageOfColor:[self facebookBlue]];
    return button;
}

- (void)authorizeServiceFromController:(UIViewController *)controller requestingUserDetails:(BOOL)loadUserDetails withCompletion:(void (^)(NSString *, OEXRegisteringUserDetails *, NSError *))completion {
    OEXFBSocial* facebookManager = [[OEXFBSocial alloc] init]; //could be named facebookHelper.
    [facebookManager loginFromController:controller completion:^(NSString *accessToken, NSError *error) {
        if(error) {
            if([error.domain isEqual:FBSDKErrorDomain] && error.code == FBSDKErrorNetwork) {
                // Hide FB specific errors inside this abstraction barrier
                error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:error.userInfo];
            }
            completion(accessToken, nil, error);
            return;
        }
        if(loadUserDetails) {
            [facebookManager requestUserProfileInfoWithCompletion:^(NSDictionary *userInfo, NSError *error) {
                // userInfo is a facebook user object
                OEXRegisteringUserDetails* profile = [[OEXRegisteringUserDetails alloc] init];
                profile.email = userInfo[@"email"];
                profile.name = userInfo[@"name"];
                completion(accessToken, profile, error);
            }];
        }
        else {
            completion(accessToken, nil, error);
        }
        
    }];
}

@end
