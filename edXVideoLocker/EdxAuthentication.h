//
//  EdxAuthentication.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 25/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserDetails.h"
extern NSString * const oauthTokenKey;
extern NSString * const clientIDKey;
extern NSString * const authTokenResponse;
extern NSString * const authTokenType;
extern NSString * const tokenReceiveNotification;
extern NSString * const loggedInUser;

typedef enum{
    FACEBOOK_LOGIN=4,
    GOOGLE_LOGIN
}SocialLoginType;

typedef void (^RequestTokenCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);

@interface EdxAuthentication : NSObject<NSURLSessionDelegate,NSURLSessionTaskDelegate>


+(void)requestTokenWithUser:(NSString * )username
                   password:(NSString * )password
          CompletionHandler:(RequestTokenCompletionHandler)completionBlock;

+ (NSString*)authHeaderForApiAccess;


-(void)getUserDetailsWithCompletionHandler:(RequestTokenCompletionHandler)completionBlock;
+(void)resetPasswordWithEmailId:(NSString *)email CSRFToken:(NSString *)token completionHandler:(RequestTokenCompletionHandler)completionBlock;

+(void)socialLoginWith:(SocialLoginType)loginType completionHandler:(RequestTokenCompletionHandler)handler;
+(void)authenticateWithAccessToken:(NSString *)token  loginType:(SocialLoginType)loginType completionHandler:(void(^)(NSData *userdata, NSURLResponse *userresponse, NSError *usererror))handler;


//-(void)getUserDetailsWithCompletionHandler:(RequestTokenCompletionHandler)completionBlock;
//+(void)loginWithFacebook;

+(BOOL)isUserLoggedIn;

+(UserDetails *)getLoggedInUser;


+(void)clearUserSessoin;

@end
