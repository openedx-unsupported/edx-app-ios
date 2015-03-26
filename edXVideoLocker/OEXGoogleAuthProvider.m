//
//  OEXGoogleAuthProvider.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXGoogleAuthProvider.h"

#import "OEXDateFormatting.h"
#import "OEXExternalAuthProviderButton.h"
#import "OEXGoogleSocial.h"
#import "OEXRegisteringUserDetails.h"

@implementation OEXGoogleAuthProvider

- (UIColor*)googleRed {
    return [UIColor colorWithRed:230./255. green:66./255. blue:55./255. alpha:1];
}

- (NSString*)displayName {
    return OEXLocalizedString(@"GOOGLE", nil);
}

- (NSString*)backendName {
    return @"google-oauth2";
}

- (OEXExternalAuthProviderButton*)freshAuthButton {
    OEXExternalAuthProviderButton* button = [[OEXExternalAuthProviderButton alloc] initWithFrame:CGRectZero];
    [button setTitle:self.displayName forState:UIControlStateNormal];
    // Because of the '+' the G icon is off center. This accounts for that.
    [button setImageEdgeInsets:UIEdgeInsetsMake(0, 3, 0, -3)];
    [button setImage:[UIImage imageNamed:@"icon_google_white"] forState:UIControlStateNormal];
    [button useBackgroundImageOfColor:[self googleRed]];
    return button;
}

- (void)authorizeServiceWithCompletion:(void (^)(NSString* token, OEXRegisteringUserDetails* userProfile, NSError* error))completion {
    [[OEXGoogleSocial sharedInstance] login:^(NSString* token, NSError* error){
        if(error) {
            [[OEXGoogleSocial sharedInstance] clearHandler];
            completion(token, nil, error);
        }
        else {
            [[OEXGoogleSocial sharedInstance] requestUserProfileInfoWithCompletion:^(GTLPlusPerson *userInfo, NSError *error) {
                OEXRegisteringUserDetails* profile = [[OEXRegisteringUserDetails alloc] init];
                GTLPlusPersonEmailsItem* email = userInfo.emails.firstObject;
                profile.email = email.value;
                profile.name = userInfo.name.formatted;
                NSDate* date = [OEXDateFormatting dateWithGPlusBirthDate:userInfo.birthday];
                if(date != nil) {
                    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:date];
                    profile.birthYear = @(components.year).description;
                }
                completion(token, profile, error);
            }];
        }
    }];
}

@end
