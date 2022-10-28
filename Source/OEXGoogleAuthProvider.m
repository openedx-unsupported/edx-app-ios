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
#import <Masonry/Masonry.h>

@implementation OEXGoogleAuthProvider

- (UIColor*)googleBlue {
    return [UIColor colorWithRed:66.0/255.0 green:133.0/255.0 blue:244.0/255.0 alpha:1];
}

- (NSString*)displayName {
    return [Strings google];
}

- (NSString*)backendName {
    return @"google-oauth2";
}

- (UIView*)makeAuthView:(NSString *)text {
    return [[ExternalProviderView alloc] initWithIconImage:self.iconImage text:text textStyle:self.textStyle backgroundColor:self.backgoundColor borderColor:[[OEXStyles sharedStyles] neutralXDark]];
}

- (UIImage*)iconImage {
    return [UIImage imageNamed:@"icon_google_white"];
}

- (UIColor*)backgoundColor {
    return [UIColor colorWithRed:255.0 green:255.0 blue:255.0 alpha:1];
}

- (OEXTextStyle*)textStyle {
    return [[OEXMutableTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeLarge color:[[[OEXStyles sharedStyles] neutralBlackT] colorWithAlphaComponent:0.54]];
}

- (void)authorizeServiceFromController:(UIViewController *)controller requestingUserDetails:(BOOL)loadUserDetails withCompletion:(void (^)(NSString * _Nullable , OEXRegisteringUserDetails * _Nullable, NSError * _Nullable))completion {

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
