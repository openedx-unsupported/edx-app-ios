//
//  OEXFBSocial.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 20/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

typedef void (^OEXFBLoginCompletionHandler)(NSString *accessToken,
                                            FBSessionState status,
                                            NSError *error);

@interface OEXFBSocial : NSObject
{
}
+ (id)sharedInstance;
-(void)login:(OEXFBLoginCompletionHandler)completionHandler;
-(void)logout;
-(void)clearHandler;
-(BOOL)isLogin;
@end
