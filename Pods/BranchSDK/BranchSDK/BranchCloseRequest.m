//
//  BranchCloseRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchCloseRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"

#if !TARGET_OS_TV
#import "BranchContentDiscoveryManifest.h"
#endif

@implementation BranchCloseRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface
                key:(NSString *)key
           callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[BRANCH_REQUEST_KEY_RANDOMIZED_BUNDLE_TOKEN] = preferenceHelper.randomizedBundleToken;
    params[BRANCH_REQUEST_KEY_SESSION_ID] =  preferenceHelper.sessionID;
    params[BRANCH_REQUEST_KEY_RANDOMIZED_DEVICE_TOKEN] = preferenceHelper.randomizedDeviceToken;
    NSDictionary *branchAnalyticsObj = [preferenceHelper getBranchAnalyticsData];
    if (branchAnalyticsObj && branchAnalyticsObj.count > 0) {
#if !TARGET_OS_TV
        NSData *data =
            [NSPropertyListSerialization
                dataWithPropertyList:branchAnalyticsObj
                format:NSPropertyListBinaryFormat_v1_0
                options:0 error:NULL];
        if ([data length] < (NSUInteger) [BranchContentDiscoveryManifest getInstance].maxPktSize) {
            params[BRANCH_CONTENT_DISCOVER_KEY] = branchAnalyticsObj;
        }
#endif
        [preferenceHelper clearBranchAnalyticsData];
    }
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_CLOSE] key:key callback:callback];
    
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // Nothing to see here
}

@end
