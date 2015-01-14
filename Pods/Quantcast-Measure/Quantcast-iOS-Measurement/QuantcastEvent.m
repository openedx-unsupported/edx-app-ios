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
#if !__has_feature(objc_arc)
#error "Quantcast Measurement is designed to be used with ARC. Please turn on ARC or add '-fobjc-arc' to this file's compiler flags"
#endif // !__has_feature(objc_arc)

#import <Foundation/Foundation.h>
#import "QuantcastMeasurement.h"
#import <sys/utsname.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "QuantcastEvent.h"
#import "QuantcastParameters.h"
#import "QuantcastPolicy.h"
#import "QuantcastUtils.h"

@interface QuantcastEvent (){
    
    NSMutableDictionary* _parameters;
    
}


-(id)getParameter:(NSString*)inParamKey;

+(NSString*)hashDeviceID:(NSString*)inDeviceID withSalt:(NSString*)inSalt;

-(void)addTimeZoneParameters;
-(void)putLabels:(id<NSObject>)inLabelsObjectOrNil withParamterKey:(NSString*)inParameterKey;

@end
#pragma mark - QuantcastEvent
@implementation QuantcastEvent

-(id)initWithSessionID:(NSString*)inSessionID timeStamp:(NSDate*)inTimeStamp {
    
    self = [super init];
    if (self) {
        _timestamp = inTimeStamp;
        _sessionID = inSessionID;
        _parameters = [NSMutableDictionary dictionaryWithCapacity:1];
        
    }
    
    return self;
}




#pragma mark - Parameter Management

-(void)putParameter:(NSString*)inParamKey withValue:(id)inValue {
    if ( nil != inValue ) {
        [_parameters setObject:inValue forKey:inParamKey];
    }
}

-(void)putParameters:(NSDictionary*)inParams{
    for(NSString* key in inParams.allKeys){
        [self putParameter:key withValue:[inParams objectForKey:key]];
    }
}

-(id)getParameter:(NSString*)inParamKey {
    return [_parameters objectForKey:inParamKey];
}

-(void)putAppLabels:(id<NSObject>)inAppLabelsObjectOrNil networkLabels:(id<NSObject>)inNetworkLabelsObjectOrNil;
{
    [self putLabels:inAppLabelsObjectOrNil withParamterKey:QCPARAMETER_APP_LABELS];
    [self putLabels:inNetworkLabelsObjectOrNil withParamterKey:QCPARAMETER_NETWORK_LABELS];
}

-(void)putLabels:(id<NSObject>)inLabelsObjectOrNil withParamterKey:(NSString*)inParameterKey {
    if ( nil != inLabelsObjectOrNil ) {
        
        if ( [inLabelsObjectOrNil isKindOfClass:[NSString class]] ) {
            NSString* encodedLabel = [QuantcastUtils urlEncodeString:(NSString*)inLabelsObjectOrNil];
            [self putParameter:inParameterKey withValue:encodedLabel];
            
        }
        else if ( [inLabelsObjectOrNil isKindOfClass:[NSArray class]] ) {
            NSArray* labelArray = (NSArray*)inLabelsObjectOrNil;
            NSString* labelsString =  [QuantcastUtils encodeLabelsList:labelArray];
            [self putParameter:inParameterKey withValue:labelsString];
        }
        else {
           QUANTCAST_ERROR(@"An incorrect object type was passed as a label (type = %@). The object passed was: %@",inParameterKey,inLabelsObjectOrNil);
        }
    }
}

-(void)addTimeZoneParameters {
    
    NSTimeZone* tz = [NSTimeZone localTimeZone];
    [self putParameter:QCPARAMETER_DST withValue:[NSNumber numberWithBool:[tz isDaylightSavingTimeForDate:self.timestamp]]];
    
    NSInteger tzMinuteOffset = [tz secondsFromGMTForDate:self.timestamp]/60;
    [self putParameter:QCPARAMETER_TZO withValue:[NSNumber numberWithInteger:tzMinuteOffset]];
}

#pragma mark - JSON conversion
-(NSDictionary*)JSONDictEnforcingPolicy:(QuantcastPolicy*)inPolicyOrNil{
    
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:_parameters.count + 2];
    [jsonDict setObject:_sessionID forKey:@"sid"];
    [jsonDict setObject:[NSString stringWithFormat:@"%qi", (int64_t)[_timestamp timeIntervalSince1970]] forKey:@"et"];
    for ( NSString* param in [_parameters allKeys]) {
        if(![inPolicyOrNil isBlacklistedParameter:param]){
            
            id value = [_parameters objectForKey:param];
            
            if([QCPARAMETER_AID isEqualToString:param] || [QCPARAMETER_DID isEqualToString:param]){
                value = [QuantcastEvent hashDeviceID:value withSalt:inPolicyOrNil.deviceIDHashSalt];
            }
            
            [jsonDict setObject:value forKey:param];
        }
    }
    
    return jsonDict;
}

#pragma mark - Debugging
- (NSString *)description {
    return [NSString stringWithFormat:@"<QuantcastEvent %p: sid = %@, timestamp = %@>", self, self.sessionID, self.timestamp ];
}

#pragma mark - Event Factory

+(NSString*)hashDeviceID:(NSString*)inDeviceID withSalt:(NSString*)inSalt {
    if ( nil != inSalt ) {
        NSString* saltedGoodness = [inDeviceID stringByAppendingString:inSalt];
        return [QuantcastUtils quantcastHash:saltedGoodness];
    }
    else {
        return inDeviceID;
    }
}

+(QuantcastEvent*)eventWithSessionID:(NSString*)inSessionID
                      eventTimestamp:(NSDate *)inTimestamp
                applicationInstallID:(NSString*)inAppInstallID
{
    QuantcastEvent* e = [[QuantcastEvent alloc] initWithSessionID:inSessionID timeStamp:inTimestamp];
    [e putParameter:QCPARAMETER_AID withValue:inAppInstallID];
    return e;
}

+(QuantcastEvent*)openSessionEventWithClientUserHash:(NSString*)inHashedUserIDOrNil
                                      eventTimestamp:(NSDate *)inTimestamp
                                    newSessionReason:(NSString*)inReason
                                      connectionType:(NSString*)connectionType
                                           sessionID:(NSString*)inSessionID
                                     quantcastAPIKey:(NSString*)inQuantcastAPIKey
                               quantcastNetworkPCode:(NSString*)inQuantcastNetworkPCode
                                    deviceIdentifier:(NSString*)inDeviceID
                                appInstallIdentifier:(NSString*)inAppInstallID
                                      eventAppLabels:(id<NSObject>)inAppLabelsOrNil
                                  eventNetworkLabels:(id<NSObject>)inNetworkLabelsOrNil
                                             carrier:(CTCarrier*)inCarrier
{
    
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];

    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_LOAD];

    [e putParameter:QCPARAMETER_REASON withValue:inReason];
    [e putParameter:QCPARAMATER_APIKEY withValue:inQuantcastAPIKey];
    [e putParameter:QCPARAMETER_NETWORKPCODE withValue:inQuantcastNetworkPCode];
    [e putParameter:QCPARAMETER_MEDIA withValue:@"app"];
    [e putParameter:QCPARAMETER_CT withValue:connectionType];
    [e putParameter:QCPARAMETER_DID withValue:inDeviceID];
    [e putParameter:QCPARAMETER_UH withValue:inHashedUserIDOrNil];
    
    Class adManagerClass = NSClassFromString(@"ASIdentifierManager");
    NSString* adManagerLinked = [[NSNumber numberWithBool:(adManagerClass != nil)] stringValue];
    [e putParameter:QCPARAMETER_IDFA_LINKED withValue:adManagerLinked];
    
    NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
    [e putParameter:QCPARAMETER_ANAME withValue:appName];
    
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    [e putParameter:QCPARAMATER_PKID withValue:appBundleID];
    
    NSString* appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [e putParameter:QCPARAMETER_AVER withValue:appVersion];

    NSString* appBuildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    [e putParameter:QCPARAMETER_IVER withValue:appBuildVersion];
    
    [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil];

    // screen resolution
    
    UIScreen* screen = [UIScreen mainScreen];
    NSString* screenResolution = [NSString stringWithFormat:@"%dx%dx32", (int)screen.bounds.size.width, (int)screen.bounds.size.height ];
    [e putParameter:QCPARAMETER_SR withValue:screenResolution];
    
    // time zone
    
    [e addTimeZoneParameters];
    
    // Fill in Carrier Data
    [e putParameter:QCPARAMETER_ICC withValue:inCarrier.isoCountryCode];
    [e putParameter:QCPARAMETER_MCC withValue:inCarrier.mobileCountryCode];
    [e putParameter:QCPARAMETER_MNN withValue:inCarrier.carrierName];
    [e putParameter:QCPARAMETER_MNC withValue:inCarrier.mobileNetworkCode];
    
    NSDate* created = [QuantcastUtils appInstallTime];
    if (nil != created) {
        [e putParameter:QCPARAMETER_INSTALL withValue:[NSString stringWithFormat:@"%lld",(long long)[created timeIntervalSince1970]*1000]];
    }

    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* platform =  [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    [e putParameter:QCPARAMETER_DMOD withValue:platform];
    
    [e putParameter:QCPARAMETER_DTYPE withValue:[[UIDevice currentDevice] model]];
    [e putParameter:QCPARAMETER_DOS withValue:[[UIDevice currentDevice] systemName]];
    [e putParameter:QCPARAMETER_DOSV withValue:[[UIDevice currentDevice] systemVersion]];
    [e putParameter:QCPARAMETER_DM withValue:@"Apple"];
    [e putParameter:QCPARAMETER_LC withValue:[[NSLocale preferredLanguages] objectAtIndex:0]];
    [e putParameter:QCPARAMETER_LL withValue:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]];
    
    return e;
}

+(QuantcastEvent*)closeSessionEventWithSessionID:(NSString*)inSessionID
                                  eventTimestamp:(NSDate *)inTimestamp
                            applicationInstallID:(NSString*)inAppInstallID
                                  eventAppLabels:(id<NSObject>)inAppLabelsOrNil
                              eventNetworkLabels:(id<NSObject>)inNetworkLabelsOrNil
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];
    
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_FINISHED];
    [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil];
    
    return e;
}

+(QuantcastEvent*)pauseSessionEventWithSessionID:(NSString*)inSessionID
                                  eventTimestamp:(NSDate *)inTimestamp
                            applicationInstallID:(NSString*)inAppInstallID
                                  eventAppLabels:(id<NSObject>)inAppLabelsOrNil
                              eventNetworkLabels:(id<NSObject>)inNetworkLabelsOrNil
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];
    
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_PAUSE];
    [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil];
    
    return e;
}

+(QuantcastEvent*)resumeSessionEventWithSessionID:(NSString*)inSessionID
                                   eventTimestamp:(NSDate *)inTimestamp
                             applicationInstallID:(NSString*)inAppInstallID
                                   eventAppLabels:(id<NSObject>)inAppLabelsOrNil
                               eventNetworkLabels:(id<NSObject>)inNetworkLabelsOrNil
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];
    
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_RESUME];
    [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil];
    
    return e;
}

+(QuantcastEvent*)logEventEventWithEventName:(NSString*)inEventName
                              eventTimestamp:(NSDate *)inTimestamp
                              eventAppLabels:(id<NSObject>)inAppLabelsOrNil
                          eventNetworkLabels:(id<NSObject>)inNetworkLabelsOrNil
                                   sessionID:(NSString*)inSessionID
                        applicationInstallID:(NSString*)inAppInstallID
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];
   
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_APPEVENT];
    [e putParameter:QCPARAMETER_APPEVENT withValue:inEventName];
    [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil];

    
    return e;
}

+(QuantcastEvent*)logNetworkEventEventWithEventName:(NSString*)inEventName
                                 eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil
                                          sessionID:(NSString*)inSessionID
                                     eventTimestamp:(NSDate *)inTimestamp
                               applicationInstallID:(NSString*)inAppInstallID
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];
    
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_NETWORKEVENT];
    [e putParameter:QCPARAMETER_NETWORKEVENT withValue:inEventName];
    [e putAppLabels:nil networkLabels:inEventNetworkLabelsOrNil];

    return e;
}

+(QuantcastEvent*)logUploadLatency:(NSUInteger)inLatencyMilliseconds
                       forUploadId:(NSString*)inUploadID
                     withSessionID:(NSString*)inSessionID
                    eventTimestamp:(NSDate *)inTimestamp
              applicationInstallID:(NSString*)inAppInstallID
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];

    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_LATENCY];
    [e putParameter:QCPARAMETER_LATENCY_UPLID withValue:inUploadID];
    [e putParameter:QCPARAMETER_LATENCY_VALUE withValue:[NSString stringWithFormat:@"%lu",(unsigned long)inLatencyMilliseconds]];
    
    return e;
}

+(QuantcastEvent*)geolocationEventWithCountry:(NSString*)inCountry
                                     province:(NSString*)inProvince
                                         city:(NSString*)inCity
                               eventTimestamp:(NSDate*)inTimestamp
                            appIsInBackground:(BOOL)inIsAppInBackground
                                withSessionID:(NSString*)inSessionID
                         applicationInstallID:(NSString*)inAppInstallID
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];
    
    [e putParameter:QCPARAMETER_AID withValue:inAppInstallID];
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_LOCATION];
    [e putParameter:QCPARAMETER_COUNTRY withValue:inCountry];
    [e putParameter:QCPARAMETER_STATE withValue:inProvince];
    [e putParameter:QCPARAMETER_LOCALITY withValue:inCity];
    if (inIsAppInBackground) {
        [e putParameter:QCPARAMETER_INBACKGROUND withValue:[[NSNumber numberWithBool:inIsAppInBackground] stringValue]];
    }
    [e addTimeZoneParameters];
    return e;
}

+(QuantcastEvent*)networkReachabilityEventWithConnectionType:(NSString*)connectionType
                                              withSessionID:(NSString*)inSessionID
                                              eventTimestamp:(NSDate *)inTimestamp
                                       applicationInstallID:(NSString*)inAppInstallID
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];

    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_NETINFO];
    [e putParameter:QCPARAMETER_CT withValue:connectionType];

    return e;
}


+(QuantcastEvent*)logSDKError:(NSString*)inSDKErrorType
              withErrorObject:(NSError*)inErrorObjectOrNil
               errorParameter:(NSString*)inErrorParameterOrNil
                withSessionID:(NSString*)inSessionID
               eventTimestamp:(NSDate *)inTimestamp
         applicationInstallID:(NSString*)inAppInstallID
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];
 
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_SDKERROR ];
    [e putParameter:QCPARAMETER_ERRORTYPE withValue:inSDKErrorType];
    [e putParameter:QCPARAMETER_ERRORDESCRIPTION withValue:[inErrorObjectOrNil description]];
    [e putParameter:QCPARAMETER_ERRORPARAMETER withValue:inErrorParameterOrNil];
    return e;
}

+(QuantcastEvent*)customEventWithSession:(NSString*)sessionId
                          eventTimestamp:(NSDate *)inTimestamp
                    applicationInstallID:(NSString*)inAppInstallID
                            parameterMap:(NSDictionary*)inParams
                          eventAppLabels:(id<NSObject>)inAppLabelsOrNil
                      eventNetworkLabels:(id<NSObject>)inNetworkLabelsOrNil{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:sessionId eventTimestamp:inTimestamp applicationInstallID:inAppInstallID];
    [e putParameters:inParams];
    [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil];
    return e;
    
}

+(QuantcastEvent*)dataBaseEvent:(NSString*)inEventId
                      timestamp:(NSDate *)inTimestamp
                  withParameterList:(NSArray*)inParamArray{
    QuantcastEvent* e = [[QuantcastEvent alloc] initWithSessionID:inEventId timeStamp:inTimestamp];
    
    for ( NSArray* eventParamRow in inParamArray ) {
        NSString* param = [eventParamRow objectAtIndex:0];
        NSString* value = [eventParamRow objectAtIndex:1];
        [e putParameter:param withValue:value];
    }
    
    return e;
}

@end
