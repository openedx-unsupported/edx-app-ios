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

#ifndef __has_feature
#define __has_feature(x) 0
#endif
#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#import <Foundation/Foundation.h>

/*!
 @class QuantcastUtils
 @internal
 */
#define QUANTCAST_LOG(fmt, ...)         {if([QuantcastUtils logging]) NSLog((@"QC Measurement: " fmt), ##__VA_ARGS__);}
#define QUANTCAST_WARN(fmt, ...)        {if([QuantcastUtils logging]) NSLog((@"QC Measurement: WARNING - " fmt), ##__VA_ARGS__);}
#define QUANTCAST_ERROR(fmt, ...)       NSLog((@"QC Measurement: ERROR -  " fmt), ##__VA_ARGS__);

#define SYSTEM_VERSION_LESS_THAN(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface QuantcastUtils : NSObject

+(NSString*)quantcastCacheDirectoryPath;
+(NSString*)quantcastCacheDirectoryPathCreatingIfNeeded;

+(NSString*)quantcastDataGeneratingDirectoryPath;
+(NSString*)quantcastDataReadyToUploadDirectoryPath;
+(NSString*)quantcastUploadInProgressDirectoryPath;

+(void)emptyAllQuantcastCaches;

+(NSString*)quantcastHash:(NSString*)inStrToHash;

+(NSData*)gzipData:(NSData*)inData error:(NSError*__autoreleasing*)outError;

/*!
 @internal
 @method handleConnection:didReceiveAuthenticationChallenge:withTrustedHost: 
 @abstract Convenience method for handdling https authentication challenges
 @discussion This method handles https authentication chalenges sent to NSURLConnectionDelegate objects
 @param connection the passed NSURLConnection
 @param challenge the passed NSURLAuthenticationChallenge
 @param inTrustedHost the domain name that self-signed certificates should be accepted from. Pass nil if none should be accepted.
 @param inEnableLogging YES if logging should be enabled
 */
+(void)handleConnection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge withTrustedHost:(NSString*)inTrustedHost;

/*!
 @internal
 @method updateSchemeForURL:
 @abstract Adjusts the URL scheme based on the linkage to the Securirty framework
 @discussion If the code is compiled with QCMEASUREMENT_USE_SECURE_CONNECTIONS defined to 1, the URL scheme will adjusted to use https. Otherwise, the URL will use http.
 @param inURL the URL to adjust. It doesn't matter what the current scheme is.
 @return The adjusted URL
 */
+(NSURL*)updateSchemeForURL:(NSURL*)inURL;

/*!
 @internal
 @method encodeLabelsList:
 @abstract converts a list of NSString labels to a single NSString properly encoded for transmission
 @param inLabelsArrayOrNil An NSArray containing one or more NSStrings
 @return A NSString that should be used for the single NSString label functions
 */
+(NSString*)encodeLabelsList:(NSArray*)inLabelsArrayOrNil;

+(id<NSObject>)combineLabels:(id<NSObject>)labels1 withLabels:(id<NSObject>)labels2;
+(NSString*)urlEncodeString:(NSString*)inString;

+(void)setLogging:(BOOL)loggingOn;
+(BOOL)logging;

+(NSString*)generateUUID;

+(NSString*)stringFromObject:(id)inJSONObject defaultValue:(NSString*)inDefaultValue;

+(NSDate*)appInstallTime;
@end
