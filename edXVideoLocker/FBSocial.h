//
//  FBSocial.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 20/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

typedef void (^LoginCompletionHandler)(NSString *accessToken,
                                      FBSessionState status,
                                      NSError *error);

@interface FBSocial : NSObject
{
}
+ (id)sharedInstance;
-(void)login:(LoginCompletionHandler)completionHandler;
-(void)logout;
-(void)clearHandler;
-(BOOL)isLogin;
@end
