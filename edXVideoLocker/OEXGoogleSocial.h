//
//  OEXGoogleSocial.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 21/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GooglePlus/GooglePlus.h>
typedef void (^OEXGoogleOEXFBLoginCompletionHandler)(NSString *accessToken,NSError *error);

@interface OEXGoogleSocial : NSObject<GPPSignInDelegate>

{
    
}
@property(nonatomic,assign)BOOL handledOpenUrl;
+ (id)sharedInstance;
-(void)googleLogin:(OEXGoogleOEXFBLoginCompletionHandler)completionHandler;
-(void)logout;
-(BOOL)isLogin;
-(void)clearHandler;
-(void)clearGoogleSession;
@end
