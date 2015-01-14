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

#ifndef QCMEASUREMENT_ENABLE_JSONKIT
#define QCMEASUREMENT_ENABLE_JSONKIT 0
#endif

#import <CoreTelephony/CTCarrier.h>
#import "QuantcastPolicy.h"
#import "QuantcastParameters.h"
#import "QuantcastUtils.h"
#import "QuantcastMeasurement.h"

#if QCMEASUREMENT_ENABLE_JSONKIT
#import "JSONKit.h"
#endif

#define QCMEASUREMENT_DO_NOT_SALT_STRING    @"MSG"

@interface QuantcastMeasurement ()
// declare "private" method here
-(void)logSDKError:(NSString*)inSDKErrorType withError:(NSError*)inErrorOrNil errorParameter:(NSString*)inErrorParametOrNil;
-(CTCarrier*)getCarrier;
@end

@interface QuantcastPolicy ()<NSURLConnectionDataDelegate> {
    NSSet* _blacklistedParams;
    NSString* _didSalt;
    BOOL _isMeasurementBlackedout;
    BOOL _allowGeoMeasurement;
    
    BOOL _policyHasBeenLoaded;
    BOOL _waitingForUpdate;
    
    double _desiredGeoLocationAccuracy;
    double _geoMeasurementUpdateDistance;
    
    NSURL* _policyURL;
    
    NSTimeInterval _sessionTimeout;
}
@property (strong, nonatomic) NSString* apiKey;
@property (strong, nonatomic) NSString* networkCode;
-(id)initWithPolicyURL:(NSURL*)inPolicyURL reachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil;
-(void)setPolicywithJSONData:(NSData*)inJSONData;
-(void)networkReachabilityChanged:(NSNotification*)inNotification;
-(void)startPolicyDownloadWithURL:(NSURL*)inPolicyURL;
-(void)sendPolicyLoadNotification;

@end


@implementation QuantcastPolicy
@synthesize deviceIDHashSalt=_didSalt;
@synthesize isMeasurementBlackedout=_isMeasurementBlackedout;
@synthesize hasPolicyBeenLoaded=_policyHasBeenLoaded;
@synthesize sessionPauseTimeoutSeconds=_sessionTimeout;
@synthesize apiKey;
@synthesize networkCode;

-(id)initWithPolicyURL:(NSURL*)inPolicyURL reachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil {
    self = [super init];
    
    if (self) {
        _sessionTimeout = QCMEASUREMENT_DEFAULT_MAX_SESSION_PAUSE_SECOND;
        
        _policyHasBeenLoaded = NO;
        _waitingForUpdate = NO;
        
        _allowGeoMeasurement = NO;
        _desiredGeoLocationAccuracy = 10.0;
        _geoMeasurementUpdateDistance = 50.0;

       // first, determine if there is a saved polciy on disk, if not, create it with default polciy
        NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPath];
        
        NSString* policyFilePath = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_POLICY_FILENAME];

        if ( [[NSFileManager defaultManager] fileExistsAtPath:policyFilePath] ) {
            
            NSData* policyData = [NSData dataWithContentsOfFile:policyFilePath];
            
            if ( policyData.length != 0 ){
                [self setPolicywithJSONData:policyData];
            }
        }
                                                              
        //
        // Now set up for a download of policy 
        _policyURL = inPolicyURL;
            
        [self downloadLatestPolicyWithReachability:inNetworkReachabilityOrNil];
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}

-(void)downloadLatestPolicyWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil {
    if ( nil != inNetworkReachabilityOrNil && nil != _policyURL && !_waitingForUpdate) {
        
        _waitingForUpdate = YES;
        _policyHasBeenLoaded = NO;
        
        // if the network is available, check to see if there is a new
        
        if ([inNetworkReachabilityOrNil currentReachabilityStatus] != QuantcastNotReachable ) {
            [self startPolicyDownloadWithURL:_policyURL];
        }
        else {
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kQuantcastNetworkReachabilityChangedNotification object:inNetworkReachabilityOrNil];
        }
    }
    
}

-(void)setPolicywithJSONData:(NSData*)inJSONData {
    if( inJSONData.length == 0) return;
    
    NSDictionary* policyDict = [self parseJsonData:inJSONData];
    
    if (nil != policyDict) {
        
        _blacklistedParams = [QuantcastPolicy blackListFromJSONArray:[policyDict objectForKey:@"blacklist"] defaultValue:nil];
        
        _didSalt = [QuantcastUtils stringFromObject:[policyDict objectForKey:@"salt"] defaultValue:nil];
        if ( [_didSalt isEqualToString:QCMEASUREMENT_DO_NOT_SALT_STRING] ) {
            _didSalt = nil;
        }
        
        _isMeasurementBlackedout = [QuantcastPolicy isBlackedOutFromJSONObject:[policyDict objectForKey:@"blackout"] defaultValue:NO];
        
        _sessionTimeout = [QuantcastPolicy doubleFromJSONObject:[policyDict objectForKey:@"sessionTimeOutSeconds"] defaultValue:QCMEASUREMENT_DEFAULT_MAX_SESSION_PAUSE_SECOND];
        
        _allowGeoMeasurement = [QuantcastPolicy boolForJSONObject:[policyDict objectForKey:@"allowGeoMeasurement"] defaultValue:YES];
        _desiredGeoLocationAccuracy = [QuantcastPolicy doubleFromJSONObject:[policyDict objectForKey:@"desiredGeoLocationAccuracy"] defaultValue:10.0];
        _geoMeasurementUpdateDistance = [QuantcastPolicy doubleFromJSONObject:[policyDict objectForKey:@"geoMeasurementUpdateDistance"] defaultValue:50.0];
        
        _policyHasBeenLoaded = YES;
        
        [self sendPolicyLoadNotification];
        
    }
}

-(NSDictionary*)parseJsonData:(NSData*)inJSONData{
    NSDictionary* policyDict = nil;
    
    if ( nil == inJSONData ) {
        [self handleError:@"Tried to set policy with a nil JSON data object."];
    }
    else {
        
        NSError* __autoreleasing jsonError = nil;
        
        // try to use NSJSONSerialization first. check to see if class is available (iOS 5 or later)
        Class jsonClass = NSClassFromString(@"NSJSONSerialization");
        
        if ( nil != jsonClass ) {
            policyDict = [jsonClass JSONObjectWithData:inJSONData
                                               options:NSJSONReadingMutableLeaves
                                                 error:&jsonError];
        }
#if QCMEASUREMENT_ENABLE_JSONKIT
        else if(nil != NSClassFromString(@"JSONDecoder")) {
            // try with JSONKit
            policyDict = [[JSONDecoder decoder] objectWithData:inJSONData error:&jsonError];
        }
#endif
        else {
            [self handleError:@"There is no available JSON decoder to user. Please enable JSONKit in your project!"];
        }
        
        if ( nil != jsonError ) {
            policyDict = nil;
            NSString* jsonStr = [[NSString alloc] initWithData:inJSONData
                                                      encoding:NSUTF8StringEncoding] ;
            [self handleError:[NSString stringWithFormat:@"Unable to parse policy JSON data. error = %@, json = %@", jsonError, jsonStr]];
        }
    }
    return policyDict;
}

-(void)handleError:(NSString*) message{
   QUANTCAST_ERROR(@"%@", message);
    _policyHasBeenLoaded = NO;
    _waitingForUpdate = NO;
}

+(NSSet*)blackListFromJSONArray:(NSArray*)inJSONArray defaultValue:(NSSet*)inDefaultValue{
    NSSet* retSet = inDefaultValue;
    if ( [inJSONArray count] > 0 ) {
        retSet = [NSSet setWithArray:inJSONArray];
    }
    return retSet;
}

+(BOOL)isBlackedOutFromJSONObject:(id)inJSONObject defaultValue:(BOOL)inDefaultValue{
    BOOL retBool = inDefaultValue;
    if ( [inJSONObject isKindOfClass:[NSString class]] || [inJSONObject isKindOfClass:[NSNumber class]]) {
        int64_t blackoutValue = [inJSONObject longLongValue]; // this value will be in terms of milliseconds since Jan 1, 1970
        
        if ( blackoutValue != 0 ) {
            NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
            NSTimeInterval blackoutTime = blackoutValue/1000.0;
            
            // check to ensure that nowTime is less than blackoutTime
            if ( nowTime < blackoutTime ) {
                retBool = YES;
            }
        }
    }
    return retBool;
}

+(double)doubleFromJSONObject:(id)inJSONObject defaultValue:(double)inDefaultValue{
    double retDouble = inDefaultValue;
    if([inJSONObject isKindOfClass:[NSString class]] || [inJSONObject isKindOfClass:[NSNumber class]]){
        retDouble = [inJSONObject doubleValue];
        if(retDouble == 0){
            retDouble = inDefaultValue;
        }
    }
    return retDouble;
}

+(BOOL)boolForJSONObject:(id)inJSONObject defaultValue:(BOOL)inDefaultValue {
    BOOL retBool = inDefaultValue;
    if([inJSONObject isKindOfClass:[NSString class]] || [inJSONObject isKindOfClass:[NSNumber class]]){
        retBool = [inJSONObject boolValue];
    }
    return retBool;
}

-(void)sendPolicyLoadNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:QUANTCAST_NOTIFICATION_POLICYLOAD object:self];
}

#pragma mark - Policy Values

-(BOOL)isBlacklistedParameter:(NSString*)inParamName {
    return [_blacklistedParams containsObject:inParamName];
}

-(void)setAllowGeoMeasurement:(BOOL)inAllowGeoMeasurement {
    _allowGeoMeasurement = inAllowGeoMeasurement;
}

-(BOOL)allowGeoMeasurement {
    return _allowGeoMeasurement;
}

-(double)desiredGeoLocationAccuracy {
    return _desiredGeoLocationAccuracy;
}

-(double)geoMeasurementUpdateDistance {
    return _geoMeasurementUpdateDistance;
}

#pragma mark - Download Handling

-(void)networkReachabilityChanged:(NSNotification*)inNotification {
    
    id<QuantcastNetworkReachability> reachabilityObj = (id<QuantcastNetworkReachability>)[inNotification object];
    
    
    if ([reachabilityObj currentReachabilityStatus] != QuantcastNotReachable ) {
        [self startPolicyDownloadWithURL:_policyURL];
    }
  
}

-(void)startPolicyDownloadWithURL:(NSURL*)inPolicyURL {
    
    if ( nil != inPolicyURL ) {
        
       QUANTCAST_LOG(@"Starting policy download with URL = %@", inPolicyURL);
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:inPolicyURL
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:QCMEASUREMENT_CONN_TIMEOUT_SECONDS];

        NSHTTPURLResponse* __autoreleasing policyResponse = nil;
        NSError* __autoreleasing policyError = nil;
        NSData* policyData = [NSURLConnection sendSynchronousRequest:request returningResponse:&policyResponse error:&policyError];
        if( nil != policyError){
            [self connectionDidFail:policyError];
            
        }
        if(policyResponse.statusCode == 200){
            [self connectionSuccess:policyData];
        }else{
            [self connectionDidFail:nil];
        }
    }
}

-(void)connectionDidFail:(NSError*)error{
    [[QuantcastMeasurement sharedInstance] logSDKError:QC_SDKERRORTYPE_POLICYDOWNLOADFAILURE
                                             withError:error
                                        errorParameter:_policyURL.description];
    
   QUANTCAST_LOG(@"Error downloading policy JSON from url %@, error = %@",  _policyURL, error );
    _waitingForUpdate = NO;
}

-(void)connectionSuccess:(NSData*)policyData{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setPolicywithJSONData:policyData];
    _waitingForUpdate = NO;
    _policyHasBeenLoaded = YES;
    [self savePolicyToFile:policyData];
}

-(void) savePolicyToFile:(NSData *)policyData
{
    
    if (QuantcastUtils.logging) {
        NSString* jsonStr = [[NSString alloc] initWithData:policyData encoding:NSUTF8StringEncoding];
       QUANTCAST_LOG(@"Successfully downloaded policy with json = %@", jsonStr);
    }
    
    // first, determine if there is a saved policy on disk, if not, create it with default polciy
    NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPath];
    NSString* policyFilePath = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_POLICY_FILENAME];
    BOOL fileWriteSuccess = [[NSFileManager defaultManager] createFileAtPath:policyFilePath contents:policyData attributes:nil];
    
    if ( !fileWriteSuccess ) {
       QUANTCAST_ERROR(@"Could not create downloaded policy JSON at path = %@",policyFilePath);
    }
}

#pragma mark - Policy Factory
#ifndef QCMEASUREMENT_POLICY_URL_FORMAT_APIKEY
#define QCMEASUREMENT_POLICY_URL_FORMAT_APIKEY      @"http://m.quantcount.com/policy.json?a=%@&v=%@&t=%@&c=%@"
#endif
#ifndef QCMEASUREMENT_POLICY_URL_FORMAT_PKID
#define QCMEASUREMENT_POLICY_URL_FORMAT_PKID        @"http://m.quantcount.com/policy.json?p=%@&n=%@&v=%@&t=%@&c=%@"
#endif
#define QCMEASUREMENT_POLICY_PARAMETER_CHILD        @"&k=YES"
+(QuantcastPolicy*)policyWithAPIKey:(NSString*)inQuantcastAPIKey networkPCode:(NSString*)inNetworkPCode networkReachability:(id<QuantcastNetworkReachability>)inReachability countryCode:(NSString*)countryCode appIsDirectAtChildren:(BOOL)inAppIsDirectedAtChildren {
    
    NSURL* policyURL = [QuantcastPolicy generatePolicyRequestURLWithAPIKey:inQuantcastAPIKey networkPCode:inNetworkPCode countryCode:countryCode appIsDirectAtChildren:inAppIsDirectedAtChildren ];
    
   QUANTCAST_LOG(@"Creating policy object with policy URL = %@", policyURL);
    
    QuantcastPolicy* policy = [[QuantcastPolicy alloc] initWithPolicyURL:policyURL reachability:inReachability];
    policy.apiKey = inQuantcastAPIKey;
    policy.networkCode = inNetworkPCode;
    
    return policy;
}

/*!
 @method generatePolicyRequestURLWithAPIKey:networkReachability:carrier:appIsDirectAtChildren:enableLogging:
 @internal
 @abstract Gerates a URL for downlaiding the most appropiate privacy policy for this app.
 @param inQuantcastAPIKey The declared API Key for this app. May be nil, in which case the app's bundle identifier is used.
 @param inReachability used to determine the country the device is in
 @param inAppIsDirectedAtChildren Whether the app has declared itself as directed at children under 13 or not. This is typically only used (that is, not NO) for network/platform integrations. Directly quantified apps (apps with an API Key) should declare their "directed at children under 13" status at the Quantcast.com website.
 @param inEnableLogging whether logging is enabled
 */
+(NSURL*)generatePolicyRequestURLWithAPIKey:(NSString*)inQuantcastAPIKey networkPCode:(NSString*)inNetworkPCode countryCode:(NSString*)inCountryCode appIsDirectAtChildren:(BOOL)inAppIsDirectedAtChildren {
    
    NSString* mcc = [inCountryCode uppercaseString];
    
    // if the cellular country is not available, use locale country as a proxy
    if ( nil == mcc ) {
        NSLocale* locale = [NSLocale currentLocale];
        
        NSString* localeCountry = [locale objectForKey:NSLocaleCountryCode];
        
        if ( nil != localeCountry ) {
            mcc = [localeCountry uppercaseString];
        }
        else {
            // country is unknown
            mcc = @"XX";
        }
    }
    
    NSString* osString;
    if (SYSTEM_VERSION_LESS_THAN(@"4.0")) {
       QUANTCAST_ERROR(@"Unable to support iOS version below 4.0");
        return nil;
    }
    else if (SYSTEM_VERSION_LESS_THAN(@"5.0")) {
        osString = @"IOS4";
    }
    else if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
        osString = @"IOS5";
    }
    else {
        osString = @"IOS";
    }
    
    NSString* policyURLStr = nil;
    
    if ( nil != inQuantcastAPIKey ) {
        policyURLStr = [NSString stringWithFormat:QCMEASUREMENT_POLICY_URL_FORMAT_APIKEY,inQuantcastAPIKey,QCMEASUREMENT_API_VERSION,osString,mcc];
    }
    else {
        NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        policyURLStr = [NSString stringWithFormat:QCMEASUREMENT_POLICY_URL_FORMAT_PKID,[QuantcastUtils urlEncodeString:appBundleID],inNetworkPCode,QCMEASUREMENT_API_VERSION,osString,mcc];
    }
    
    if ( inAppIsDirectedAtChildren ) {
        policyURLStr = [policyURLStr stringByAppendingString:QCMEASUREMENT_POLICY_PARAMETER_CHILD];
        
    }
    
    NSURL* policyURL =  [QuantcastUtils updateSchemeForURL:[NSURL URLWithString:policyURLStr]];
    
    return policyURL;
}
@end
