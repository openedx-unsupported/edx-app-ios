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

@class QuantcastMeasurement;
@protocol QuantcastOptOutDelegate;

/*!
 @class QuantcastOptOutViewController
 @internal
 */
@interface QuantcastOptOutViewController : UIViewController

@property (unsafe_unretained,nonatomic) id<QuantcastOptOutDelegate> delegate;

-(id)initWithDelegate:(id<QuantcastOptOutDelegate>)inDelegate;

@end
