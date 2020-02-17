// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDNotifications.h"

static NSString *s_webAuthDidStartLoadNotificationName;
static NSString *s_webAuthDidFinishLoadNotificationName;
static NSString *s_webAuthDidFailNotificationName;
static NSString *s_webAuthDidCompleteNotificationName;
static NSString *s_webAuthWillSwitchToBrokerAppNotificationName;
static NSString *s_webAuthDidReceiveResponseFromBrokerNotificationName;

@implementation MSIDNotifications

+ (void)setWebAuthDidFailNotificationName:(NSString *)webAuthDidFailNotificationName
{
    s_webAuthDidFailNotificationName = webAuthDidFailNotificationName;
}
+ (NSString *)webAuthDidFailNotificationName { return s_webAuthDidFailNotificationName; }
                                             
+ (void)setWebAuthDidCompleteNotificationName:(NSString *)webAuthDidCompleteNotificationName
{
    s_webAuthDidCompleteNotificationName = webAuthDidCompleteNotificationName;
}
+ (NSString *)webAuthDidCompleteNotificationName { return s_webAuthDidCompleteNotificationName; }

+ (void)setWebAuthDidStartLoadNotificationName:(NSString *)webAuthDidStartLoadNotificationName
{
    s_webAuthDidStartLoadNotificationName = webAuthDidStartLoadNotificationName;
}
+ (NSString *)webAuthDidStartLoadNotificationName { return s_webAuthDidStartLoadNotificationName; }

+ (void)setWebAuthDidFinishLoadNotificationName:(NSString *)webAuthDidFinishLoadNotificationName
{
    s_webAuthDidFinishLoadNotificationName = webAuthDidFinishLoadNotificationName;
}
+ (NSString *)webAuthDidFinishLoadNotificationName { return s_webAuthDidFinishLoadNotificationName; }

+ (void)setWebAuthWillSwitchToBrokerAppNotificationName:(NSString *)webAuthWillSwitchToBrokerAppNotificationName
{
    s_webAuthWillSwitchToBrokerAppNotificationName = webAuthWillSwitchToBrokerAppNotificationName;
}

+ (NSString *)webAuthWillSwitchToBrokerAppNotificationName { return s_webAuthWillSwitchToBrokerAppNotificationName; }

+ (void)setWebAuthDidReceiveResponseFromBrokerNotificationName:(NSString *)webAuthDidReceiveResponseFromBrokerNotificationName
{
    s_webAuthDidReceiveResponseFromBrokerNotificationName = webAuthDidReceiveResponseFromBrokerNotificationName;
}

+ (NSString *)webAuthDidReceiveResponseFromBrokerNotificationName { return s_webAuthDidReceiveResponseFromBrokerNotificationName; }

#pragma mark - Notifications
+ (void)notifyWebAuthDidStartLoad:(NSURL *)url userInfo:(NSDictionary *)userInfo
{
    if (s_webAuthDidStartLoadNotificationName)
    {
        NSMutableDictionary *notificationInfo = [NSMutableDictionary new];
        [notificationInfo addEntriesFromDictionary:userInfo];
        
        if (url) notificationInfo[@"url"] = url;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:s_webAuthDidStartLoadNotificationName
                                                            object:nil
                                                          userInfo:notificationInfo];
    }
}

+ (void)notifyWebAuthDidFinishLoad:(NSURL *)url userInfo:(NSDictionary *)userInfo
{
    if (s_webAuthDidFinishLoadNotificationName)
    {
        NSMutableDictionary *notificationInfo = [NSMutableDictionary new];
        [notificationInfo addEntriesFromDictionary:userInfo];
        
        if (url) notificationInfo[@"url"] = url;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:s_webAuthDidFinishLoadNotificationName
                                                            object:nil
                                                          userInfo:notificationInfo];
    }
}

+ (void)notifyWebAuthDidFailWithError:(NSError *)error
{
    if (s_webAuthDidFailNotificationName)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:s_webAuthDidFailNotificationName
                                                            object:nil
                                                          userInfo:error ? @{ @"error" : error } : nil];
    }
}

+ (void)notifyWebAuthDidCompleteWithURL:(NSURL *)url
{
    if (s_webAuthDidCompleteNotificationName)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:s_webAuthDidCompleteNotificationName
                                                            object:self
                                                          userInfo:url ? @{ @"url" : url } : nil];
    }
    
}

+ (void)notifyWebAuthWillSwitchToBroker
{
    if (s_webAuthWillSwitchToBrokerAppNotificationName)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:s_webAuthWillSwitchToBrokerAppNotificationName
                                                            object:nil];
    }
}

+ (void)notifyWebAuthDidReceiveResponseFromBroker:(MSIDTokenResult *)result
{
    if (s_webAuthDidReceiveResponseFromBrokerNotificationName)
    {
        NSDictionary *userInfo = nil;

        if (result)
        {
            userInfo = @{@"response": result};
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:s_webAuthDidReceiveResponseFromBrokerNotificationName
                                                            object:nil
                                                          userInfo:userInfo];
    }
}

@end
