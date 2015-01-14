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

#import <zlib.h>
#import "QuantcastUtils.h"
#import "QuantcastParameters.h"
#import "QuantcastMeasurement.h"

#ifndef QCMEASUREMENT_USE_SECURE_CONNECTIONS
#define QCMEASUREMENT_USE_SECURE_CONNECTIONS 0
#endif

static BOOL _enableLogging = NO;

@interface QuantcastMeasurement ()
// declare "private" method here
-(void)logSDKError:(NSString*)inSDKErrorType withError:(NSError*)inErrorOrNil errorParameter:(NSString*)inErrorParametOrNil;

@end

@interface QuantcastUtils ()

+(int64_t)qhash2:(const int64_t)inKey string:(NSString*)inString;

+(NSURL*)adjustURL:(NSURL*)inURL toSecureConnection:(BOOL)inUseSecure;


@end

@implementation QuantcastUtils

+(NSString*)quantcastCacheDirectoryPath {
    NSArray* cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    if ( [cachePaths count] > 0 ) {
        
        NSString* cacheDir = [cachePaths objectAtIndex:0];
        
        NSString* qcCachePath = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_CACHE_DIRNAME];
        
        return qcCachePath;
    }

    return nil;
}

+(NSString*)quantcastCacheDirectoryPathCreatingIfNeeded {
    NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDir]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil]){
            QUANTCAST_LOG(@"Unable to create cache directory = %@", cacheDir );
            return nil;
        }
    }
    
    return cacheDir;
}

+(NSString*)quantcastDataGeneratingDirectoryPath {
    NSString*  cacheDir = [QuantcastUtils quantcastCacheDirectoryPath];
    
    cacheDir = [cacheDir stringByAppendingPathComponent:@"generating"];   
    
    // determine if directory exists. If it doesn't create it.
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDir]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil]){
            QUANTCAST_LOG(@"Unable to create cache directory = %@", cacheDir );
            return nil;
        }
    }
    
    return cacheDir;
}

+(NSString*)quantcastDataReadyToUploadDirectoryPath {
    NSString*  cacheDir = [QuantcastUtils quantcastCacheDirectoryPath];
    
    cacheDir =  [cacheDir stringByAppendingPathComponent:@"ready"];
    // determine if directory exists. If it doesn't create it.
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDir]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil]){
            QUANTCAST_LOG(@"Unable to create cache directory = %@", cacheDir );
            return nil;
        }
    }
    
    return cacheDir;
}
+(NSString*)quantcastUploadInProgressDirectoryPath {
    NSString*  cacheDir = [QuantcastUtils quantcastCacheDirectoryPath];
    
    cacheDir = [cacheDir stringByAppendingPathComponent:@"uploading"];
    // determine if directory exists. If it doesn't create it.
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDir]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil]){
            QUANTCAST_LOG(@"Unable to create cache directory = %@", cacheDir );
            return nil;
        }
    }
    
    return cacheDir;
}

+(void)emptyAllQuantcastCaches {
    NSFileManager* fileManager = [NSFileManager defaultManager];    
    
    NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPath];
    
    NSError* __autoreleasing dirError = nil;
    NSArray* dirContents = [fileManager contentsOfDirectoryAtPath:cacheDir error:&dirError];
    
    if ( nil == dirError && [dirContents count] > 0 ) {
        
        NSSet* filesToKeepSet = [NSSet setWithObjects:QCMEASUREMENT_POLICY_FILENAME, nil];
        
        for (NSString* filename in dirContents) {
            if ( ![filesToKeepSet containsObject:filename] ) {
                NSError* __autoreleasing error = nil;
                
                [fileManager removeItemAtPath:[[QuantcastUtils quantcastCacheDirectoryPath] stringByAppendingPathComponent:filename] error:&error];
                if (nil != error) {
                    QUANTCAST_LOG(@"Unable to delete Quantcast Cache directory! error = %@", error);
                }

            }
        }
    } 
}

+(int64_t)qhash2:(const int64_t)inKey string:(NSString*)inString {
    
    const char * str = [inString UTF8String];
    
    int64_t h = inKey;
    
    for (NSUInteger i = 0; i < [inString length]; ++i ) {
        int32_t h32 = (int32_t)h; // javascript only does bit shifting on 32 bits, must mimic that here
        
        char character = str[i];
        
        h32 ^= character;
        
        h = h32;
        
        h += (int64_t)(h32 << 1)+(h32 << 4)+(h32 << 7)+(h32 << 8)+(h32 << 24);
    }
    
    return h;
}


+(NSString*)quantcastHash:(NSString*)inStrToHash {
    const int64_t h1 = 0x811c9dc5;
    const int64_t h2 = 0xc9dc5118;
    
    double hash1 = [QuantcastUtils qhash2:h1 string:inStrToHash];
    double hash2 = [QuantcastUtils qhash2:h2 string:inStrToHash];
    
    int64_t value = round( fabs(hash1*hash2)/(double)65536.0 );
    
    NSString* hashStr = [NSString stringWithFormat:@"%qx", value];
    
    return hashStr;
}

+(NSData*)gzipData:(NSData*)inData error:(NSError*__autoreleasing*)outError {
    if (!inData || [inData length] == 0)  
    {  
        if ( NULL != outError ) {
            NSDictionary* errDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Could not compress an empty or null NSData object", nil] 
                                                            forKeys:[NSArray arrayWithObjects:NSLocalizedDescriptionKey, nil]];
        
            *outError = [NSError errorWithDomain:@"QuantcastMeasurment" code:-1 userInfo:errDict];
        }
        return nil;  
    }  
    int gzipErr;
    
    z_stream gzipStream;
    
    gzipStream.zalloc = Z_NULL;
    gzipStream.zfree = Z_NULL;
    gzipStream.opaque = Z_NULL;
    gzipStream.total_out = 0;
    gzipStream.next_in = (Bytef*)[inData bytes];
    gzipStream.avail_in = (uInt)[inData length];
    
    gzipErr = deflateInit2(&gzipStream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15+16, 8, Z_DEFAULT_STRATEGY );
    
    if ( Z_OK != gzipErr ) {
        
        if ( NULL != outError ) {
            NSString* errMsg;
            
            switch (gzipErr) {
                case Z_MEM_ERROR:
                    errMsg = @"Insufficient memory available to init compression library.";
                    break;
                case Z_STREAM_ERROR:
                    errMsg = @"Invalid compression level passed to compression library.";
                    break;
                case Z_VERSION_ERROR:
                    errMsg = @"zlib library version (zlib_version) is incompatible with the version assumed by the caller.";
                    break;
                default:
                    if ( NULL != gzipStream.msg ) {
                        errMsg = [NSString stringWithFormat:@"zlib err = %s", gzipStream.msg];
                    }
                    else {
                        errMsg = @"Unknown compression error.";
                    }
                    break;
            }
            
            NSDictionary* errDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:errMsg, nil] 
                                                                forKeys:[NSArray arrayWithObjects:NSLocalizedDescriptionKey, nil]];
            
            *outError = [NSError errorWithDomain:@"QuantcastMeasurment" code:gzipErr userInfo:errDict];
            
        }
        
        return nil;
    }
    
    int compResult = Z_OK;


    
    NSMutableData* compressedResults = [NSMutableData dataWithLength:[inData length]*1.25];
    
    while ( Z_OK == compResult ) {
        
        if (gzipStream.total_out >= [compressedResults length]) {
            [compressedResults increaseLengthBy:[inData length]*0.5];
        }
        
        gzipStream.next_out = [compressedResults mutableBytes] + gzipStream.total_out;
        gzipStream.avail_out = (uInt)([compressedResults length] - gzipStream.total_out);
        
        
        compResult = deflate(&gzipStream, Z_FINISH );
    }
    
    if ( Z_STREAM_END != compResult ) {
        if ( NULL != outError ) {
            NSString* errMsg;
        
            switch (compResult) {
                case Z_STREAM_ERROR:
                    errMsg = @"stream state was inconsistent (for example if next_in or next_out was NULL)";
                    break;
                default:
                    if ( NULL != gzipStream.msg ) {
                        errMsg = [NSString stringWithFormat:@"zlib err = %s", gzipStream.msg];
                    }
                    else {
                        errMsg = @"Unknown compression error.";
                    }
                    break;
            }
            NSDictionary* errDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:errMsg, nil] 
                                                                forKeys:[NSArray arrayWithObjects:NSLocalizedDescriptionKey, nil]];
            
            *outError = [NSError errorWithDomain:@"QuantcastMeasurment" code:gzipErr userInfo:errDict];
            
            deflateEnd(&gzipStream);
        }
        return nil;            
    }    
    
    [compressedResults setLength:gzipStream.total_out];
    
    deflateEnd(&gzipStream);
    
    return [NSData dataWithData:compressedResults];
}

+(void)handleConnection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge withTrustedHost:(NSString*)inTrustedHost {
 
#if QCMEASUREMENT_USE_SECURE_CONNECTIONS
    NSUInteger prevFailures = challenge.previousFailureCount;
    
    
    if ( 0 == prevFailures && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] ) {
        
        SecTrustResultType trustResult;
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        
        
        OSStatus err = SecTrustEvaluate(trust, &trustResult);
        
        NSURLCredential* credentials = [NSURLCredential credentialForTrust:trust];
        
        if ((err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified))) {
            [challenge.sender useCredential:credentials forAuthenticationChallenge:challenge];
            QUANTCAST_LOG(@"Handled an authentication challenge from %@", challenge.protectionSpace.host );
            return;
        }
        
        
        // could not validate credentials. Check to see if acceptable.

        //
        // frequently invalid certificate issues are caused by the device's date being set years into the past, like 1970.
        // This is before the "valid on" date for the certificate. check for that and report error appropiately. Since the
        // Quantcast SDK was published first in January, 2013, use that date as the check. Crude, but most date failures on iOS
        // devices are due to battery failure and inability to connect to a cellular carrier, so the date resets to 1970.
        //
        // seconds since epoch for January 1, 2013 is: 1356998400
        //

        const NSTimeInterval QCMEASUREMENT_REFERENCE_TIMESTAMP = (NSTimeInterval)1356998400;
        NSDate* nowDate = [NSDate date];
        NSDate* validCheckDate = [NSDate dateWithTimeIntervalSince1970:QCMEASUREMENT_REFERENCE_TIMESTAMP];

        if ( nil != inTrustedHost && [inTrustedHost compare:challenge.protectionSpace.host] == NSOrderedSame && trustResult == kSecTrustResultRecoverableTrustFailure && [nowDate compare:validCheckDate] == NSOrderedAscending ) {
            
             
            
            SecTrustSetVerifyDate(trust, (__bridge CFDateRef)validCheckDate);
            err = SecTrustEvaluate(trust, &trustResult);
            
            if ((err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified))) {
                
                [challenge.sender useCredential:credentials forAuthenticationChallenge:challenge];
            
                QUANTCAST_LOG(@"Accepted invalid trust certificates from %@ due to device date = %@", challenge.protectionSpace.host, nowDate );
                return;
            }
        }
        
        // challenge could not be authenticated. reject.

        [challenge.sender cancelAuthenticationChallenge:challenge];

        QUANTCAST_LOG(@"QC Measurement: Could not validate trust certificates from %@", challenge.protectionSpace.host );
        
        NSError* error = [[NSError alloc] initWithDomain:@"QCAuthenticationError" code:1 userInfo:@{ NSLocalizedDescriptionKey: @"Could not validate trust certificate", NSURLErrorFailingURLStringErrorKey : [[connection currentRequest] URL] } ];
        
        [[QuantcastMeasurement sharedInstance] logSDKError:QC_SDKERRORTYPE_HTTPSAUTHCHALLENGE
                                                 withError:error
                                            errorParameter:challenge.protectionSpace.host];
    }
    else {
        [challenge.sender cancelAuthenticationChallenge:challenge];
        
        QUANTCAST_LOG(@"Got an unhandled authentication challenge from %@", challenge.protectionSpace.host );
        NSError* error = [[NSError alloc] initWithDomain:@"QCAuthenticationError" code:2 userInfo:@{ NSLocalizedDescriptionKey: @"Unhandled authentication challenge", NSURLErrorFailingURLStringErrorKey : [[connection currentRequest] URL] } ];
        [[QuantcastMeasurement sharedInstance] logSDKError:QC_SDKERRORTYPE_HTTPSAUTHCHALLENGE
                                                 withError:error
                                            errorParameter:challenge.protectionSpace.host];
        
    }
#endif
}

+(NSURL*)updateSchemeForURL:(NSURL*)inURL {
#if QCMEASUREMENT_USE_SECURE_CONNECTIONS
    return [QuantcastUtils adjustURL:inURL toSecureConnection:YES];
#else
    return [QuantcastUtils adjustURL:inURL toSecureConnection:NO];
#endif
}

/*!
 @internal
 @method adjustURL:toSecureConnection:
 @abstract Adjusts the URL to use a secure connection or not
 @discussion This method is factored out primarily for unit testing
 @param inURL The URL to adjust
 @param inUseSecure Whether the adjusted URL should use https or not
 @return the adjusted URL. Returns the original URL if it is malformed.
 */
+(NSURL*)adjustURL:(NSURL*)inURL toSecureConnection:(BOOL)inUseSecure {
    
    NSString* urlStr = [inURL absoluteString];
    
    // find the "://" part
    
    NSRange range = [urlStr rangeOfString:@"://"];
    
    if ( range.location == NSNotFound ) {
        return inURL;
    }
    
    NSString* newURLFormat = @"http%@";
    
    if (inUseSecure) {
        newURLFormat = @"https%@";
    }
    
    
    NSString* newURLStr = [NSString stringWithFormat:newURLFormat,[urlStr substringFromIndex:range.location]];
    
    return [NSURL URLWithString:newURLStr];
}

+(id<NSObject>)combineLabels:(id<NSObject>)labels1 withLabels:(id<NSObject>)labels2 {
    if (nil == labels2) {
        return labels1;
    }
    else if (nil == labels1){
        return labels2;
    }
    
    NSMutableSet* set = [NSMutableSet set];
    if ( [labels1 isKindOfClass:[NSArray class]] ) {
        [set addObjectsFromArray:(NSArray*)labels1];
    }
    else {
        [set addObject:labels1];
    }
    
    if ( [labels2 isKindOfClass:[NSArray class]] ) {
        [set addObjectsFromArray:(NSArray*)labels2];
    }
    else {
        [set addObject:labels2];
    }
    
    return [set allObjects];
}


+(NSString*)encodeLabelsList:(NSArray*)inLabelsArrayOrNil {
    if ( nil == inLabelsArrayOrNil ) {
        return nil;
    }
    
    NSString* encodedLabels = nil;
    
    for (id object in inLabelsArrayOrNil ) {
        
        if ( [object isKindOfClass:[NSString class]]) {
        
            NSString* label = (NSString*)object;
            NSString* encodedString = [QuantcastUtils urlEncodeString:label];
        
            if ( nil == encodedLabels ) {
                encodedLabels = encodedString;
            }
            else {
                encodedLabels = [NSString stringWithFormat:@"%@,%@",encodedLabels,encodedString];
            }
        }
        else {
            QUANTCAST_ERROR(@"A label was passed in an NSArray that was not a NSString. label = %@", object);
        }
    }
    
    return encodedLabels;
}

+(NSString *)urlEncodeString:(NSString*)inString {
	NSString* encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes( kCFAllocatorDefault, (CFStringRef)inString, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding) ));


    return encodedString;
}

+(void)setLogging:(BOOL)loggingOn{
    _enableLogging = loggingOn;
}

+(BOOL)logging{
    return _enableLogging;
}

+(NSString*)generateUUID {
    CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDStr = CFUUIDCreateString(kCFAllocatorDefault, newUUID);
    
    NSString* uuid = [NSString stringWithString:(__bridge NSString*)UUIDStr];
    
    CFRelease(UUIDStr);
    CFRelease(newUUID);
    
    return uuid;
}

+(NSString*)stringFromObject:(id)inObject defaultValue:(NSString*)inDefaultValue{
    NSString* retString = inDefaultValue;
    if ( [inObject isKindOfClass:[NSString class]] ) {
        retString = (NSString*)inObject;
    }
    else if ([inObject isKindOfClass:[NSNumber class]] ) {
        NSNumber* number = (NSNumber*)inObject;
        retString = [number stringValue];
    }
    return retString;
}

+(NSDate*)appInstallTime {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0) {
        NSString* base = [paths objectAtIndex:0];
        NSError* __autoreleasing error = nil;
        NSDictionary* attrib = [[NSFileManager defaultManager] attributesOfItemAtPath:base error:&error];
        if (nil != error) {
            QUANTCAST_LOG(@"Error getting file attributes = %@ ", error );
        }
        else {
            NSDate* created = [attrib objectForKey:NSFileCreationDate];
            if (nil != created) {
                return created;
            }
        }
    }
    
    return nil;
}

@end
