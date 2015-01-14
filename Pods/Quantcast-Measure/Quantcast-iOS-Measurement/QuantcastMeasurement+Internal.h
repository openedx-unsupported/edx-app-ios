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

#import "QuantcastMeasurement.h"
#import "QuantcastEventLogger.h"

@interface QuantcastMeasurement (Internal) <QuantcastEventLogger>
@property (readonly,nonatomic) BOOL hasNetworkIntegration;
@property (readonly,nonatomic) BOOL isMeasurementActive;
@property (readonly,nonatomic) id<NSObject> internalSDKAppLabels;
@property (readonly,nonatomic) id<NSObject> internalSDKNetworkLabels;

-(NSString*)internalBeginSessionWithAPIKey:(NSString*)inQuantcastAPIKey attributedNetwork:(NSString*)inNetworkPCode userIdentifier:(NSString*)inUserIdentifierOrNil appLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil appIsDeclaredDirectedAtChildren:(BOOL)inAppIsDirectedAtChildren;

-(void)internalEndMeasurementSessionWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels;

-(void)internalPauseSessionWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels;

-(void)internalResumeSessionWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels;

-(NSString*)internalRecordUserIdentifier:(NSString*)inUserIdentifierOrNil withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels;

-(void)internalLogEvent:(NSString*)inEventName withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels;

-(void)addInternalSDKAppLabels:(NSArray*)inAppLabels networkLabels:(NSArray*)inNetworkLabels;

@end
