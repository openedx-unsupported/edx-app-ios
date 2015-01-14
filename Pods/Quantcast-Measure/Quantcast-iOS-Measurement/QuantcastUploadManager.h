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

#import <UIKit/UIKit.h>
#import "QuantcastNetworkReachability.h"

@class QuantcastDataManager;

/*!
 @class QuantcastUploadManager
 @internal
 */
@interface QuantcastUploadManager : NSObject

-(id)initWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil;




#pragma mark - Upload Management

/*!
 @internal
 @method initiateUploadForReadyJSONFilesWithDataManager:
 @abstract scans for the ready directory for JSON files, then initiates a transfer for each, subject to a rate limit
 @param inDataManager the data manger that latency tracking events should be posted to.
 */
-(void)initiateUploadForReadyJSONFilesWithDataManager:(QuantcastDataManager*)inDataManager;


@end
