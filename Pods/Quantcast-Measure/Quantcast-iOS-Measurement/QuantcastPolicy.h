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

#import <CoreTelephony/CTCarrier.h>
#import <Foundation/Foundation.h>
#import "QuantcastNetworkReachability.h"

/*!
 @class QuantcastPolicy
 @internal
 */

#define QUANTCAST_NOTIFICATION_POLICYLOAD @"quantcast-privacy-policy-load"

@interface QuantcastPolicy : NSObject

@property (readonly) NSString* deviceIDHashSalt;
@property (readonly) BOOL isMeasurementBlackedout;
@property (readonly) BOOL hasPolicyBeenLoaded;
@property (readonly) NSTimeInterval sessionPauseTimeoutSeconds;
@property (readonly) BOOL allowGeoMeasurement;
@property (readonly) double desiredGeoLocationAccuracy;
@property (readonly) double geoMeasurementUpdateDistance;
@property (readonly) NSString* apiKey;
@property (readonly) NSString* networkCode;

+(QuantcastPolicy*)policyWithAPIKey:(NSString*)inQuantcastAPIKey networkPCode:(NSString*)inNetworkPCode networkReachability:(id<QuantcastNetworkReachability>)inReachability countryCode:(NSString*)countryCode appIsDirectAtChildren:(BOOL)inAppIsDirectedAtChildren;
-(void)downloadLatestPolicyWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil;
-(BOOL)isBlacklistedParameter:(NSString*)inParamName;

@end