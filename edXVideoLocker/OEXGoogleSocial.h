//
//  OEXGoogleSocial.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 21/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleOpenSource/GoogleOpenSource.h>

typedef void (^OEXGoogleOEXLoginCompletionHandler)(NSString* accessToken, NSError* error);

@interface OEXGoogleSocial : NSObject

@property(nonatomic, assign) BOOL handledOpenUrl;
+ (instancetype)sharedInstance;
- (void)login:(OEXGoogleOEXLoginCompletionHandler)completionHandler;
- (void)logout;
- (BOOL)isLogin;
- (void)clearHandler;
- (void)clearGoogleSession;

- (void)requestUserProfileInfoWithCompletion:(void (^)(GTLPlusPerson* userInfo, NSString* profileEmail, NSError* error))completion;
@end
