//
//  OEXAuthentication.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 25/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXAppDelegate.h"
#import "OEXAuthentication.h"
#import "EDXConfig.h"
#import "EDXEnvironment.h"
#import "OEXInterface.h"
#import "NSDictionary+OEXEncoding.h"
#import "OEXFBSocial.h"
#import "OEXGoogleSocial.h"
#import "OEXUserDetails.h"
#import "OEXSession.h"
NSString * const authTokenResponse=@"authTokenResponse";
NSString * const oauthTokenKey = @"oauth_token";
NSString * const authTokenType =@"token_type";
NSString * const loggedInUser  =@"loginUserDetails";

NSString * const facebook_login_endpoint=@"facebook";
NSString * const google_login_endpoint=@"google-oauth2";


typedef void(^OEXSocialLoginCompletionHandler)(NSString *accessToken ,NSError *error);

@interface OEXAuthentication ()
@property(nonatomic,strong)OEXAcessToken *edxToken;
@end

@implementation OEXAuthentication

//This method gets called when user try to login with username password
+(void)requestTokenWithUser:(NSString * )username password:(NSString * )password CompletionHandler:(RequestTokenCompletionHandler)completionBlock

{
    NSString *body = [self plainTextAuthorizationHeaderForUserName:username password:password];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[EDXEnvironment shared].config.apiHostURL, AUTHORIZATION_URL]]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
        if (httpResp.statusCode == 200) {
            NSError *error;
            NSDictionary *dictionary =[NSJSONSerialization  JSONObjectWithData:data options:kNilOptions error:&error];
            OEXAcessToken *token=[[OEXAcessToken alloc] initWithTokenDetails:dictionary];
            [OEXAuthentication handleSuccessLoginFullWith:token completionHandler:completionBlock];
            
        }else{
            completionBlock(data,response,error);
        }
        
    }]resume];
    
}

////This method is used to reset user password
+(void)resetPasswordWithEmailId:(NSString *)email CSRFToken:(NSString *)token completionHandler:(RequestTokenCompletionHandler)completionBlock{
    
    NSString* string = [@{@"email" : email} oex_stringByUsingFormEncoding];
    NSData *postData = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[EDXEnvironment shared].config.apiHostURL, URL_RESET_PASSWORD]]];
    [request addValue:token forHTTPHeaderField:@"Cookie"];
    NSArray *parse = [token componentsSeparatedByString:@"="];
    [request addValue:[parse objectAtIndex:1] forHTTPHeaderField:@"X-CSRFToken"];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        completionBlock(data,response,error);
    }]resume];
    
}

// This retuns header for password authentication method
+(NSString*)plainTextAuthorizationHeaderForUserName:(NSString*)userName password:(NSString*)password {
    
    NSString* clientID = [[EDXEnvironment shared].config oauthClientID];
    NSString* clientSecret = [[EDXEnvironment shared].config oauthClientSecret];
    return [@{
              @"client_id" : clientID,
              @"client_secret" : clientSecret,
              @"grant_type" : @"password",
              @"username" : userName,
              @"password" : password
              } oex_stringByUsingFormEncoding];
    
}


//// This methods is used to get user details when user access token is available
-(void)getUserDetailsWith:(OEXAcessToken *)edxToken completionHandler:(RequestTokenCompletionHandler)completionBlock{
    
    self.edxToken=edxToken;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSURLSessionConfiguration *config=[NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session =[NSURLSession sessionWithConfiguration:config
                                                         delegate:self
                                                    delegateQueue:nil];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[EDXEnvironment shared].config.apiHostURL, URL_GET_USER_INFO]]];
    NSString *authValue = [NSString stringWithFormat:@"%@ %@",edxToken.tokenType,edxToken.accessToken];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (!error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200)
            {
                completionBlock(data,response,error);
            }
        }
    }];
    [task resume];
    
}

// Retuns authentication header for every authenticatated webservice call
+(NSString *)authHeaderForApiAccess{
    OEXSession *session= [OEXSession getActiveSessoin];
    if(session.edxToken){
        if(session.edxToken.accessToken){
            if(session.edxToken.tokenType){
                NSString *header = [NSString stringWithFormat:@"%@ %@",session.edxToken.tokenType,session.edxToken.accessToken];
                return header;
            }else{
                NSString *header = [NSString stringWithFormat:@"%@",session.edxToken.accessToken];
                return header;
            }
        }
    }
    return nil ;
    
}

#pragma mark NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)redirectResponse
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler{
    
    NSMutableURLRequest *mutablerequest = [request mutableCopy];
    NSString *authValue = [NSString stringWithFormat:@"%@ %@",self.edxToken.tokenType,self.edxToken.accessToken];
    [mutablerequest setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    completionHandler([mutablerequest copy]);
    
}

+(void)clearUserSessoin{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([OEXAuthentication getLoggedInUser])
        {
            ELog(@"clearUserSessoin -1");
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:loggedInUser];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [FBSession.activeSession closeAndClearTokenInformation];
            [[OEXGoogleSocial sharedInstance] logout];
            [OEXSession closeAndClearSession];
            
        }
        ELog(@"clearUserSessoin -2");
    });
    
}

+(BOOL)isUserLoggedIn{
    return [OEXUserDetails currentUser]!=nil;
}

+(OEXUserDetails *)getLoggedInUser
{
    return [OEXUserDetails currentUser];
    
}

+(void)saveUserCredentials{
    
}


#pragma mark Social Login Mrthods

+(void)loginWithGoogle:(OEXSocialLoginCompletionHandler)handler{
    [[OEXGoogleSocial sharedInstance] googleLogin:^(NSString *accessToken , NSError *error){
        handler(accessToken,error);
    }];
}

+(void)loginWithFacebook:(OEXSocialLoginCompletionHandler)handler{
    
    [[OEXFBSocial sharedInstance]login:^(NSString *sessionToken, FBSessionState status, NSError *error) {
        //[[FBSocial sharedInstance]logout];
        switch (status) {
            case FBSessionStateOpen:
            {
                handler([FBSession.activeSession accessTokenData].accessToken,error);
            }
                break;
            case FBSessionStateClosed:{
                
            }
                break;
            case FBSessionStateClosedLoginFailed:
                handler(nil,error);
                break;
            default:
                break;
        }
    }];
}



+(void)socialLoginWith:(OEXSocialLoginType)loginType completionHandler:(RequestTokenCompletionHandler)handler{
    switch (loginType) {
        case OEXFacebookLogin: {
            [OEXAuthentication loginWithFacebook:^(NSString *accessToken,NSError *error) {
                if(accessToken){
                    [OEXAuthentication authenticateWithAccessToken:accessToken loginType:OEXFacebookLogin completionHandler:handler];
                }else{
                    handler(nil,nil,error);
                }
            }];
            break;
        }
        case OEXGoogleLogin: {
            [OEXAuthentication loginWithGoogle:^(NSString *accessToken , NSError *error) {
                if(accessToken){
                    [OEXAuthentication authenticateWithAccessToken:accessToken loginType:OEXGoogleLogin completionHandler:handler];
                }else{
                    handler(nil,nil,error);
                }
            }];
            break;
        }
            
        default:{
            handler(nil,nil,nil);
            break;
        }
    }
}


+(void)authenticateWithAccessToken:(NSString *)token  loginType:(OEXSocialLoginType)loginType completionHandler:(void(^)(NSData *userdata, NSURLResponse *userresponse, NSError *usererror))handler{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSString *endpath;
    if(loginType == OEXFacebookLogin) {
        endpath=facebook_login_endpoint;
    } else {
        endpath=google_login_endpoint;
    }
    /// Create  request object to authenticate accesstoken
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/",[EDXEnvironment shared].config.apiHostURL,URL_SOCIAL_LOGIN, endpath]]];
    NSString* string = [@{@"access_token" : token} oex_stringByUsingFormEncoding];
    NSData *postData = [string dataUsingEncoding:NSUTF8StringEncoding];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
            if (httpResp.statusCode == 204) {
                OEXAcessToken *edToken=[[OEXAcessToken alloc] init];
                edToken.accessToken=token;
                [OEXAuthentication handleSuccessLoginFullWith:edToken completionHandler:handler];
                return ;
            }
            else if(httpResp.statusCode==401)
            {
                [[OEXGoogleSocial sharedInstance]clearGoogleSession];
                error=[NSError errorWithDomain:@"Not valid user" code:401 userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:@"You are not associated with edx please sigun up from website"] forKeys:[NSArray arrayWithObject:@"failed"]]];
            }
        }
        handler(data,response,error);
    }]resume];
    
}


+(void)handleSuccessLoginFullWith:(OEXAcessToken *)edxToken completionHandler:(RequestTokenCompletionHandler )completionHandeler{
    
    OEXAuthentication *edxAuth=[[OEXAuthentication alloc] init];
    [edxAuth getUserDetailsWith:edxToken completionHandler:^(NSData *userdata, NSURLResponse *userresponse, NSError *usererror) {
    
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) userresponse;
            if (httpResp.statusCode == 200) {
                NSDictionary *dictionary =[NSJSONSerialization  JSONObjectWithData:userdata options:kNilOptions error:nil];
                [OEXSession createSessionWithAccessToken:edxToken andUserDetails:dictionary];
            }
                completionHandeler(userdata,userresponse,usererror);
            
    }];
    
}


@end
