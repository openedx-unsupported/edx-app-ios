//
//  GoogleSocial.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 21/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GooglePlus/GooglePlus.h>
typedef void (^GoogleLoginCompletionHandler)(NSString *accessToken,NSError *error);

@interface GoogleSocial : NSObject<GPPSignInDelegate>

{

}
+ (id)sharedInstance;
-(void)googleLogin:(GoogleLoginCompletionHandler)completionHandler;
-(void)logout;
-(BOOL)isLogin;
-(void)clearHandler;
-(void)clearGoogleSession;
@end
