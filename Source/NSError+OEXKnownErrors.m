//
//  NSError+OEXKnownErrors.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSError+OEXKnownErrors.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@implementation NSError (OEXKnownErrors)

- (BOOL)oex_isNoInternetConnectionError {
    return ([self.domain isEqualToString:NSURLErrorDomain] &&
            (self.code == kCFURLErrorNotConnectedToInternet || self.code == kCFURLErrorNetworkConnectionLost)) ||
    ([self.domain isEqual:FBSDKErrorDomain] && self.code == FBSDKNetworkErrorCode);
}

@end
