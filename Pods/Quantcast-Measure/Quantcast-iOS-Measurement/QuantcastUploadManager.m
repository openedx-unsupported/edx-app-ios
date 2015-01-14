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

#import "QuantcastUploadManager.h"
#import "QuantcastDataManager.h"
#import "QuantcastUtils.h"
#import "QuantcastParameters.h"
#import "QuantcastNetworkReachability.h"
#import "QuantcastEvent.h"
#import "QuantcastMeasurement.h"

@interface QuantcastMeasurement ()
// declare "private" method here
-(void)logUploadLatency:(NSUInteger)inLatencyMilliseconds forUploadId:(NSString*)inUploadID;
-(void)logSDKError:(NSString*)inSDKErrorType withError:(NSError*)inErrorOrNil errorParameter:(NSString*)inErrorParametOrNil;

@end

@interface QuantcastUploadManager (){
    dispatch_queue_t _uploadQueue;
}
@property (readonly,nonatomic) BOOL ableToUpload;

-(void)networkReachabilityChanged:(NSNotification*)inNotification;
-(void)uploadJSONFile:(NSString*)inJSONFilePath dataManager:(QuantcastDataManager*)inDataManager;


@end

@implementation QuantcastUploadManager

-(id)initWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil;
{
    self = [super init];
    
    if (self) {
        _uploadQueue = dispatch_queue_create("com.quntcast.measurement.upload", DISPATCH_QUEUE_SERIAL);
        // if there is no Reachability object, assume we are debugging and enable uploading
        _ableToUpload = YES;
        
        if ( nil != inNetworkReachabilityOrNil ) {
         
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kQuantcastNetworkReachabilityChangedNotification object:inNetworkReachabilityOrNil];

            
            if ( [inNetworkReachabilityOrNil currentReachabilityStatus] == QuantcastNotReachable ){
                _ableToUpload = NO;
            }
        }
        
        // check uploading directory for any unfinished uploads, and move them to ready to upload directory
        NSError* __autoreleasing dirError = nil;
        NSFileManager* fileManager = [NSFileManager defaultManager];
        
        NSString* uploadingDir = [QuantcastUtils quantcastUploadInProgressDirectoryPath];
        NSArray* dirContents = [fileManager contentsOfDirectoryAtPath:uploadingDir error:&dirError];
        
        if ( nil == dirError && [dirContents count] > 0 ) {
            NSString* readyToUploadDirPath = [QuantcastUtils quantcastDataReadyToUploadDirectoryPath];

            for (NSString* filename in dirContents) {
                NSString*  currentFilePath = [uploadingDir stringByAppendingPathComponent:filename];
                
                if ([filename hasSuffix:@"json"]) {
                    NSString* newFilePath = [readyToUploadDirPath stringByAppendingPathComponent:filename];
                    
                    
                    NSError* __autoreleasing error = nil;
                    
                    if ( ![fileManager moveItemAtPath:currentFilePath toPath:newFilePath error:&error] ) {
                        // error, will robinson
                       QUANTCAST_LOG(@"Could not relocate file '%@' to '%@'. Error = %@", currentFilePath, newFilePath, error );
                        
                    }

                }
                
            }
            
        }        
        
    }
    
    return self;
}

-(void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && (!defined(__IPHONE_6_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0))
    //dispatch_release was changed to ARC in iOS6.  Anytime before then we have to do it manually
    dispatch_release(_uploadQueue);
#endif
    
}

-(void)networkReachabilityChanged:(NSNotification*)inNotification {
   
    id<QuantcastNetworkReachability> reachabilityObj = (id<QuantcastNetworkReachability>)[inNotification object];
    
    if ( [reachabilityObj currentReachabilityStatus] == QuantcastNotReachable ){
        _ableToUpload = NO;
    }
    else {
        _ableToUpload = YES;
    }

}

#pragma mark - Upload Management

-(void)initiateUploadForReadyJSONFilesWithDataManager:(QuantcastDataManager*)inDataManager {
    
    if (_ableToUpload ) {
        
        dispatch_async(_uploadQueue, ^{
            __block NSInteger backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                [[UIApplication sharedApplication] endBackgroundTask: backgroundTaskID];
            }];
            //
            // first, get the list of json files in the ready directory, then initiate a transfer for each
            //
            NSFileManager* fileManager = [NSFileManager defaultManager];
            
            NSString* readyDirPath = [QuantcastUtils quantcastDataReadyToUploadDirectoryPath];
            
            NSError* __autoreleasing dirError = nil;
            NSArray* dirContents = [fileManager contentsOfDirectoryAtPath:readyDirPath error:&dirError];
            
            if ( nil == dirError && [dirContents count] > 0 ) {
                for (NSString* filename in dirContents) {
                    if ( [filename hasSuffix:@"json"] ) {
                        NSString* filePath = [readyDirPath stringByAppendingPathComponent:filename];
                        // get teh upload ID from the file
                        [self uploadJSONFile:filePath dataManager:inDataManager];
                    }
                }
            }
            [[UIApplication sharedApplication] endBackgroundTask: backgroundTaskID];
        });
    }
}

-(void)uploadJSONFile:(NSString*)inJSONFilePath dataManager:(QuantcastDataManager*)inDataManager {    
    
    NSString* __autoreleasing uploadID = nil;
    NSString* __autoreleasing uploadingFilePath = nil;
    
    // get NSURLRequest
    
    NSURLRequest* urlRequest = [self urlRequestForJSONFile:inJSONFilePath reportingUploadID:&uploadID newFilePath:&uploadingFilePath];
    
    if ( nil == uploadID ) {
        // some kind of error. don't upload
       QUANTCAST_LOG(@"Could not upload JSON file '%@' because upload ID was not found in contents", inJSONFilePath );
        return;
    }
    
    // send it!
        
    NSTimeInterval startTime = NSDate.timeIntervalSinceReferenceDate;
    NSHTTPURLResponse* __autoreleasing uploadResponse = nil;
    NSError* __autoreleasing uploadError = nil;
    [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&uploadResponse error:&uploadError];
    
    if( nil != uploadError){
        [[QuantcastMeasurement sharedInstance] logSDKError:QC_SDKERRORTYPE_UPLOADFAILURE
                                                 withError:uploadError
                                            errorParameter:uploadID];
    }
    
    if(uploadResponse.statusCode == 200){
        QUANTCAST_LOG(@"Success at uploading json file '%@' to %@", uploadingFilePath, [urlRequest URL] );
        NSError* __autoreleasing fileError = nil;
        
        [[NSFileManager defaultManager] removeItemAtPath:uploadingFilePath error:&fileError];
        
        if (fileError != nil) {
            QUANTCAST_LOG(@"Error while deleting upload JSON file '%@', error = %@", uploadingFilePath, fileError );
        }
        
        // record latency
        NSTimeInterval delta = NSDate.timeIntervalSinceReferenceDate - startTime;
        NSUInteger latency = delta*1000;
        [[QuantcastMeasurement sharedInstance] logUploadLatency:latency forUploadId:uploadID];
    }else{
        [self uploadFailedForJsonFile:uploadingFilePath];
    }

}

-(void)uploadFailedForJsonFile:(NSString*)inJsonPath {
    
    NSString* newFilePath = [[QuantcastUtils quantcastDataReadyToUploadDirectoryPath] stringByAppendingPathComponent:[inJsonPath lastPathComponent]];
    
    NSError* __autoreleasing error = nil;
    
    if ( ![[NSFileManager defaultManager] moveItemAtPath:inJsonPath toPath:newFilePath error:&error] ) {
       QUANTCAST_LOG(@"Could not relocate file '%@' to '%@'. Error = %@", inJsonPath, newFilePath, error );
    }else{
       QUANTCAST_LOG(@"Upload of file '%@' failed. Moved to '%@'", inJsonPath, newFilePath);
    }
    
    
}

-(NSURLRequest*)urlRequestForJSONFile:(NSString*)inJSONFilePath 
                    reportingUploadID:(NSString*__autoreleasing*)outUploadID
                          newFilePath:(NSString*__autoreleasing*)outNewFilePath 
{
    
    // set upload ID to nil to start with. Only report it if request gene is successful
    
    (*outUploadID) = nil;
    
    NSError* __autoreleasing compressError = nil;
    
    NSData* uncompressedBodyData = [NSData dataWithContentsOfFile:inJSONFilePath];

    NSData* bodyData = [QuantcastUtils gzipData:uncompressedBodyData error:&compressError];
    
    if ( nil != compressError ) {
       QUANTCAST_LOG(@"Error while trying to compress upload data = %@", compressError);
        return nil;
    }
    
    NSURL* postURL = [QuantcastUtils updateSchemeForURL:[NSURL URLWithString:QCMEASUREMENT_UPLOAD_URL]];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:postURL 
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                                       timeoutInterval:QCMEASUREMENT_CONN_TIMEOUT_SECONDS];
    
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];	
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];	
    [request setHTTPBody:bodyData];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-Length"];
    
    //
    // move the file to the uploading diretory to signify that a url request has been generated and no new ones should be created.
    //
    
    NSString* filename = [inJSONFilePath lastPathComponent];
    
    (*outNewFilePath) = [[QuantcastUtils quantcastUploadInProgressDirectoryPath] stringByAppendingPathComponent:filename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:(*outNewFilePath)]) {
       QUANTCAST_LOG(@"Upload file '%@' already exists at path '%@'. Deleting ...", filename, (*outNewFilePath) );
        [[NSFileManager defaultManager] removeItemAtPath:(*outNewFilePath) error:nil];
    }

    NSError* __autoreleasing error = nil;

    if ( ![[NSFileManager defaultManager] moveItemAtPath:inJSONFilePath toPath:(*outNewFilePath) error:&error] ) {
       QUANTCAST_LOG(@"Could note move file '%@' to location '%@'. Error = %@", inJSONFilePath, (*outNewFilePath), [error localizedDescription] );
        return nil;
    }
    
    // now extract upload id from JSON
    NSString* jsonStr = [[NSString alloc] initWithData:uncompressedBodyData encoding:NSUTF8StringEncoding];
    
    NSRange keyRange = [jsonStr rangeOfString:@"\"uplid\":\""];
    
    jsonStr = [jsonStr substringWithRange:NSMakeRange(NSMaxRange(keyRange), 36)];
    (*outUploadID) = jsonStr;
    
    return request;
}

#pragma mark - Debugging

- (NSString *)description {
    return [NSString stringWithFormat:@"<QuantcastUploadManager %p>", self ];
}

@end
