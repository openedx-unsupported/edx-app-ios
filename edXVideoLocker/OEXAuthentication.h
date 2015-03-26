//
//  OEXAuthentication.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 25/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXUserDetails;
@protocol OEXExternalAuthProvider;

extern NSString* const oauthTokenKey;
extern NSString* const clientIDKey;
extern NSString* const tokenReceiveNotification;

typedef NS_ENUM (NSUInteger, OEXSocialLoginType) {
    OEXFacebookLogin = 4,
    OEXGoogleLogin
};

typedef void (^ OEXURLRequestHandler)(NSData* data, NSHTTPURLResponse* response, NSError* error);


// This whole class should be destroyed and replaced with a thing that generates NSURLRequests
// Then we can send the URLRequest through a generic network layer
@interface OEXAuthentication : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

+ (void)requestTokenWithUser:(NSString* )username
                    password:(NSString* )password
           completionHandler:(OEXURLRequestHandler)completionBlock;

+ (void)requestTokenWithProvider:(id <OEXExternalAuthProvider>)provider externalToken:(NSString*)token completion:(OEXURLRequestHandler)completionBlock;

+ (NSString*)authHeaderForApiAccess;

+ (void)resetPasswordWithEmailId:(NSString*)email completionHandler:(OEXURLRequestHandler)completionBlock;
// TODO: Migrate social login to use OEXExternalAuthProvider instead of casing out an enum
// This way it will be easier for people to put in other auth types
+ (void)socialLoginWith:(OEXSocialLoginType)loginType completionHandler:(OEXURLRequestHandler)handler;
+ (void)authenticateWithAccessToken:(NSString*)token loginType:(OEXSocialLoginType)loginType completionHandler:(OEXURLRequestHandler)handler;

+ (void)registerUserWithParameters:(NSDictionary*)parameters completionHandler:(OEXURLRequestHandler)handler;

@end
