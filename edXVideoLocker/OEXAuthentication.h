//
//  OEXAuthentication.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 25/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXUserDetails.h"

extern NSString* const oauthTokenKey;
extern NSString* const clientIDKey;
extern NSString* const tokenReceiveNotification;

typedef NS_ENUM (NSUInteger, OEXSocialLoginType) {
    OEXFacebookLogin = 4,
    OEXGoogleLogin
};

typedef void (^ OEXURLRequestHandler)(NSData* data, NSURLResponse* response, NSError* error);

@interface OEXAuthentication : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

+ (void)requestTokenWithUser:(NSString* )username
                    password:(NSString* )password
           completionHandler:(OEXURLRequestHandler)completionBlock;
+ (NSString*)authHeaderForApiAccess;

+ (void)resetPasswordWithEmailId:(NSString*)email CSRFToken:(NSString*)token completionHandler:(OEXURLRequestHandler)completionBlock;
+ (void)socialLoginWith:(OEXSocialLoginType)loginType completionHandler:(OEXURLRequestHandler)handler;
+ (void)authenticateWithAccessToken:(NSString*)token loginType:(OEXSocialLoginType)loginType completionHandler:(OEXURLRequestHandler)handler;

+ (BOOL)isUserLoggedIn;

+ (OEXUserDetails*)getLoggedInUser;

+ (void)clearUserSession;

+ (void)registerUserWithParameters:(NSDictionary*)parameters completionHandler:(OEXURLRequestHandler)handler;

@end
