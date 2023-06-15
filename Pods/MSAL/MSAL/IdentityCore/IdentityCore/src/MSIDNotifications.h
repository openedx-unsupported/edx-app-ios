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

#import <Foundation/Foundation.h>

@class MSIDTokenResult;

@interface MSIDNotifications : NSObject

#pragma mark - Web auth notifications
/*! Fired at the start of a resource load in the webview.
    The URL of the load, if available, will be in the @"url" key in the userInfo dictionary */
@property (class) NSString *webAuthDidStartLoadNotificationName;

/*! Fired when a resource finishes loading in the webview.
    The URL of the load, if available, will be in the @"url" key in the userInfo dictionary */
@property (class) NSString *webAuthDidFinishLoadNotificationName;

/*! Fired when web authentication fails due to reasons originating from the network.
    Look at the @"error" key in the userInfo dictionary for more details.*/
@property (class) NSString *webAuthDidFailNotificationName;

/*! Fired when authentication finishes
    The URL of the end URL, if available, will be in the @"url" key in the userInfo dictionary */
@property (class) NSString *webAuthDidCompleteNotificationName;

#pragma mark - Broker notifications
/*! Fired before MSID invokes the broker app */
@property (class) NSString *webAuthWillSwitchToBrokerAppNotificationName;

/*! Fired when the application receives a response from the broker. Look at the @"response"
    key in the userInfo dictionary for the broker response */
@property (class) NSString *webAuthDidReceiveResponseFromBrokerNotificationName;

#pragma mark - Notification callers
+ (void)notifyWebAuthDidStartLoad:(NSURL *)url userInfo:(NSDictionary *)userInfo;
+ (void)notifyWebAuthDidFinishLoad:(NSURL *)url userInfo:(NSDictionary *)userInfo;
+ (void)notifyWebAuthDidFailWithError:(NSError *)error;
+ (void)notifyWebAuthDidCompleteWithURL:(NSURL *)url;
+ (void)notifyWebAuthWillSwitchToBroker;
+ (void)notifyWebAuthDidReceiveResponseFromBroker:(MSIDTokenResult *)result;

@end
