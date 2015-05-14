//
//  NSError+OEXKnownErrors.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSError+OEXKnownErrors.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NSString* const OEXErrorDomain = @"org.edx.error";

@implementation NSError (OEXKnownErrors)

+ (NSError*)oex_courseContentLoadError {
    return [NSError errorWithDomain:OEXErrorDomain
                               code:OEXErrorCodeCouldNotLoadCourseContent
                           userInfo:@{
                                      NSLocalizedDescriptionKey : OEXLocalizedString(@"UNABLE_TO_LOAD_COURSE_CONTENT", nil)
                                          }];
}

- (BOOL)oex_isNoInternetConnectionError {
    return ([self.domain isEqualToString:NSURLErrorDomain] &&
            (self.code == kCFURLErrorNotConnectedToInternet || self.code == kCFURLErrorNetworkConnectionLost)) ||
    ([self.domain isEqual:FBSDKErrorDomain] && self.code == FBSDKNetworkErrorCode);
}

@end
