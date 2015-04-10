//
//  OEXNetworkUtility.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 23/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "OEXNetworkUtility.h"
#import "OEXConfig.h"
#import "OEXZeroRatingConfig.h"

@implementation OEXNetworkUtility

+ (BOOL)isOnZeroRatedNetwork {
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXZeroRatingConfig* zeroRatedConfig = [config zeroRatingConfig];
    NSArray* zeroRatedCarriers = [zeroRatedConfig carriers];
    CTTelephonyNetworkInfo* networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier* carrier = [networkInfo subscriberCellularProvider];
    // Get carrier name
    NSString* carrierCode = [carrier mobileNetworkCode];
    return [zeroRatedCarriers containsObject:carrierCode];
}
@end
