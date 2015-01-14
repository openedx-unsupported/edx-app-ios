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
#import "QuantcastNetworkReachability.h"

@class QuantcastPolicy;

/*!
 @class QuantcastEvent
 @internal
 */
@interface QuantcastEvent : NSObject

@property (readonly) NSDate* timestamp;
@property (readonly) NSString* sessionID;
@property (readonly) NSDictionary* parameters;

-(id)initWithSessionID:(NSString*)inSessionID timeStamp:(NSDate*)inTimeStamp;

-(void)putParameter:(NSString*)inParamKey withValue:(id)inValue;
-(void)putAppLabels:(id<NSObject>)inAppLabelsObjectOrNil networkLabels:(id<NSObject>)inNetworkLabelsObjectOrNil;

#pragma mark - JSON conversion
-(NSDictionary*)JSONDictEnforcingPolicy:(QuantcastPolicy*)inPolicyOrNil;


#pragma mark - Event Factory
+(QuantcastEvent*)eventWithSessionID:(NSString*)inSessionID
                      eventTimestamp:(NSDate *)inTimestamp
                applicationInstallID:(NSString*)inAppInstallID;


+(QuantcastEvent*)openSessionEventWithClientUserHash:(NSString*)inHashedUserIDOrNil
                                      eventTimestamp:(NSDate *)inTimestamp
                                    newSessionReason:(NSString*)inReason
                                      connectionType:(NSString*)connectionType
                                           sessionID:(NSString*)inSessionID
                                     quantcastAPIKey:(NSString*)inQuantcastAPIKey
                               quantcastNetworkPCode:(NSString*)inQuantcastNetworkPCode
                                    deviceIdentifier:(NSString*)inDeviceID
                                appInstallIdentifier:(NSString*)inAppInstallID
                                      eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                                  eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil
                                             carrier:(CTCarrier*)inCarrier;

+(QuantcastEvent*)closeSessionEventWithSessionID:(NSString*)inSessionID
                                  eventTimestamp:(NSDate *)inTimestamp
                            applicationInstallID:(NSString*)inAppInstallID
                                  eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                              eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil;

+(QuantcastEvent*)pauseSessionEventWithSessionID:(NSString*)inSessionID
                                  eventTimestamp:(NSDate *)inTimestamp
                            applicationInstallID:(NSString*)inAppInstallID
                                  eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                              eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil;

+(QuantcastEvent*)resumeSessionEventWithSessionID:(NSString*)inSessionID
                                   eventTimestamp:(NSDate *)inTimestamp
                             applicationInstallID:(NSString*)inAppInstallID
                                   eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                               eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil;


+(QuantcastEvent*)logEventEventWithEventName:(NSString*)inEventName
                              eventTimestamp:(NSDate *)inTimestamp
                              eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                          eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil
                                   sessionID:(NSString*)inSessionID
                        applicationInstallID:(NSString*)inAppInstallID;

+(QuantcastEvent*)logNetworkEventEventWithEventName:(NSString*)inEventName
                                 eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil
                                          sessionID:(NSString*)inSessionID
                                     eventTimestamp:(NSDate *)inTimestamp
                               applicationInstallID:(NSString*)inAppInstallID;

+(QuantcastEvent*)logUploadLatency:(NSUInteger)inLatencyMilliseconds\
                       forUploadId:(NSString*)inUploadID
                     withSessionID:(NSString*)inSessionID
                    eventTimestamp:(NSDate *)inTimestamp
              applicationInstallID:(NSString*)inAppInstallID;

+(QuantcastEvent*)geolocationEventWithCountry:(NSString*)inCountry
                                     province:(NSString*)inProvince
                                         city:(NSString*)inCity
                               eventTimestamp:(NSDate*)inTimestamp
                            appIsInBackground:(BOOL)inIsAppInBackground
                                withSessionID:(NSString*)inSessionID
                         applicationInstallID:(NSString*)inAppInstallID;

+(QuantcastEvent*)networkReachabilityEventWithConnectionType:(NSString*)connectionType
                                               withSessionID:(NSString*)inSessionID
                                              eventTimestamp:(NSDate *)inTimestamp
                                        applicationInstallID:(NSString*)inAppInstallID;

+(QuantcastEvent*)logSDKError:(NSString*)inSDKErrorType
              withErrorObject:(NSError*)inErrorDescOrNil
               errorParameter:(NSString*)inErrorParametOrNil
                withSessionID:(NSString*)inSessionID
               eventTimestamp:(NSDate *)inTimestamp
         applicationInstallID:(NSString*)inAppInstallID;

+(QuantcastEvent*)customEventWithSession:(NSString*)sessionId
                          eventTimestamp:(NSDate *)inTimestamp
                    applicationInstallID:(NSString*)inAppInstallID
                            parameterMap:(NSDictionary*)inParams
                          eventAppLabels:(id<NSObject>)inAppLabelsOrNil
                      eventNetworkLabels:(id<NSObject>)inNetworkLabelsOrNil;

+(QuantcastEvent*)dataBaseEvent:(NSString*)inEventId
                      timestamp:(NSDate *)inTimestamp
                  withParameterList:(NSArray*)inParamArray;

@end