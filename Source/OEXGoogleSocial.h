//
//  OEXGoogleSocial.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 21/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleSignIn/GoogleSignIn.h>

typedef void (^OEXGoogleOEXLoginCompletionHandler)(NSString* accessToken, NSError* error);

@interface OEXGoogleSocial : NSObject

@property(nonatomic, assign) BOOL handledOpenUrl;
+ (instancetype)sharedInstance;
- (void)loginFromController:(UIViewController*)controller withCompletion:(OEXGoogleOEXLoginCompletionHandler)completionHandler;
- (void)logout;
- (BOOL)isLogin;
- (void)clearHandler;

- (void)requestUserProfileInfoWithCompletion:(void (^)(GIDProfileData*))completion;
@end
