/*
 * © Copyright 2012-2014 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License. Unauthorized use of this file constitutes
 * copyright infringement and violation of law.
 */


#import <Foundation/Foundation.h>

@class QuantcastPolicy;
@class QuantcastEvent;

@protocol QuantcastEventLogger <NSObject>
@required
@property (readonly,nonatomic) BOOL isOptedOut;
@property (strong,nonatomic) NSString* currentSessionID;
@property (readonly) NSString* appInstallIdentifier;
@property (readonly) QuantcastPolicy* policy;


-(void)recordEvent:(QuantcastEvent*)inEvent;
-(void)logSDKError:(NSString*)inSDKErrorType withError:(NSError*)inErrorOrNil errorParameter:(NSString*)inErrorParametOrNil;
-(void)launchOnQuantcastThread:(void (^)(NSDate *))block;
@end
