//
//  OEXAuthentication.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 25/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN
@class OEXUserDetails;
@protocol OEXExternalAuthProvider;

extern NSString* const oauthTokenKey;
extern NSString* const clientIDKey;
extern NSString* const tokenReceiveNotification;

typedef void (^ OEXURLRequestHandler)(NSData* _Nullable data, NSHTTPURLResponse* _Nullable response, NSError* _Nullable error);


// This whole class should be destroyed and replaced with a thing that generates NSURLRequests
// Then we can send the URLRequest through a generic network layer
@interface OEXAuthentication : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

+ (void)requestTokenWithUser:(NSString* )username
                    password:(NSString* )password
           completionHandler:(OEXURLRequestHandler)completionBlock;

+ (void)requestTokenWithProvider:(id <OEXExternalAuthProvider>)provider externalToken:(NSString*)token completion:(OEXURLRequestHandler)completionBlock;

+ (NSString*)authHeaderForApiAccess;

+ (void)resetPasswordWithEmailId:(NSString*)email completionHandler:(OEXURLRequestHandler)completionBlock;

+ (void)registerUserWithApiVersion:(NSString*)apiVersion paramaters:(NSDictionary*)parameters completionHandler:(OEXURLRequestHandler)handler;

@end

NS_ASSUME_NONNULL_END
