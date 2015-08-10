//
//  NSError+OEXKnownErrors.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSError+OEXKnownErrors.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "OEXCoursewareAccess.h"

NSString* const OEXErrorDomain = @"org.edx.error";

@implementation NSError (OEXKnownErrors)

+ (NSError*)oex_courseContentLoadError {
    return [self errorWithDomain:OEXErrorDomain
                            code:OEXErrorCodeCouldNotLoadCourseContent
                        userInfo:@{
                                   NSLocalizedDescriptionKey : OEXLocalizedString(@"UNABLE_TO_LOAD_COURSE_CONTENT", nil)
                                   }];
}

+ (NSError*)oex_invalidURLError {
    return [self errorWithDomain:OEXErrorDomain
                            code:OEXErrorCodeInvalidURL
                        userInfo:@{
                                   NSLocalizedDescriptionKey : OEXLocalizedString(@"UNABLE_TO_LOAD_COURSE_CONTENT", nil)
                                   }];
}

+ (NSError*)oex_unknownError {
    return [self errorWithDomain:OEXErrorDomain
                            code:OEXErrorCodeUnknown
                        userInfo:@{
                                   NSLocalizedDescriptionKey : OEXLocalizedString(@"UNABLE_TO_LOAD_COURSE_CONTENT", nil)
                                   }];
}

+ (NSError*)oex_errorWithCoursewareAccess:(OEXCoursewareAccess*)access {
    return [[self alloc] initWithDomain: OEXErrorDomain
                                   code:OEXErrorCodeCoursewareAccess
                               userInfo:@{
                                          NSLocalizedDescriptionKey : access.user_message ?: OEXLocalizedString(@"UNABLE_TO_LOAD_COURSE_CONTENT", nil)
                                          }];
}

- (BOOL)oex_isNoInternetConnectionError {
    return ([self.domain isEqualToString:NSURLErrorDomain] &&
            (self.code == kCFURLErrorNotConnectedToInternet || self.code == kCFURLErrorNetworkConnectionLost)) ||
    ([self.domain isEqual:FBSDKErrorDomain] && self.code == FBSDKNetworkErrorCode);
}
@end
