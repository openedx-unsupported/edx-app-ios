//
//  OEXAuthentication.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 25/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXUserDetails.h"

extern NSString * const oauthTokenKey;
extern NSString * const clientIDKey;
extern NSString * const tokenReceiveNotification;


typedef NS_ENUM(NSUInteger, OEXSocialLoginType) {
    OEXFacebookLogin = 4,
    OEXGoogleLogin
};

typedef void (^RequestTokenCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);

@interface OEXAuthentication : NSObject<NSURLSessionDelegate,NSURLSessionTaskDelegate>


+(void)requestTokenWithUser:(NSString * )username
                   password:(NSString * )password
          CompletionHandler:(RequestTokenCompletionHandler)completionBlock;
+ (NSString*)authHeaderForApiAccess;

+(void)resetPasswordWithEmailId:(NSString *)email CSRFToken:(NSString *)token completionHandler:(RequestTokenCompletionHandler)completionBlock;
+(void)socialLoginWith:(OEXSocialLoginType)loginType completionHandler:(RequestTokenCompletionHandler)handler;
+(void)authenticateWithAccessToken:(NSString *)token  loginType:(OEXSocialLoginType)loginType completionHandler:(void(^)(NSData *userdata, NSURLResponse *userresponse, NSError *usererror))handler;

+(BOOL)isUserLoggedIn;

+(OEXUserDetails *)getLoggedInUser;

+(void)clearUserSession;

+(void)registerUserWith:(NSDictionary *)parameters completionHandler:(RequestTokenCompletionHandler) handler;

@end
