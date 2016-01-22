//
//  OEXGoogleSocial.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 21/11/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

#import <GoogleSignIn/GoogleSignIn.h>

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END
