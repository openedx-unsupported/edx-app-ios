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

@class QuantcastDatabase;
@class QuantcastEvent;
@class QuantcastUploadManager;
@class QuantcastPolicy;
@protocol QuantcastNetworkReachability;

/*!
 @class QuantcastDataManager
 @internal
 */
@interface QuantcastDataManager : NSObject
@property (nonatomic) NSUInteger uploadEventCount;
@property (nonatomic) NSUInteger backgroundUploadEventCount;

-(id)initWithOptOut:(BOOL)inOptOutStatus;

/*!
 @internal
 @method enableDataUploading
 @abstract data uploading is not enabled by default. This is done mostly for unit testing purposes. This method must be called before data uploading can start.
 */
-(void)enableDataUploadingWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachability;

#pragma mark - Recording Events


-(void)recordEvent:(QuantcastEvent*)inEvent withPolicy:(QuantcastPolicy*)inPolicy;
-(void)recordEventWithoutUpload:(QuantcastEvent*)inEvent withPolicy:(QuantcastPolicy*)inPolicy;
-(void)initiateDataUploadWithPolicy:(QuantcastPolicy*)inPolicy;

#pragma mark - Opt-Out Handling
@property (nonatomic) BOOL isOptOut;



@end
