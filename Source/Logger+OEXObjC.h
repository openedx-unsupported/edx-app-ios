//
//  Logger+OEXObjC.h
//  edX
//
//  Created by Akiva Leffert on 9/15/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "edX-Swift.h"

NS_ASSUME_NONNULL_BEGIN

#define OEXLogDebug(_domain, _format, ...) [Logger logDebug:_domain file: @"" __FILE__ line:__LINE__ format:_format, ##__VA_ARGS__]
#define OEXLogInfo(_domain, _format, ...) [Logger logInfo:_domain file: @"" __FILE__ line:__LINE__ format:_format, ##__VA_ARGS__]
#define OEXLogError(_domain, _format, ...) [Logger logError:_domain file: @"" __FILE__ line:__LINE__ format:_format, ##__VA_ARGS__]

@interface Logger (OEXObjC)

+ (void)logDebug:(NSString*)domain file:(NSString*)file line:(NSUInteger)line format:(NSString*)format, ... NS_FORMAT_FUNCTION(4, 5);
+ (void)logInfo:(NSString*)domain file:(NSString*)file line:(NSUInteger)line format:(NSString*)format, ... NS_FORMAT_FUNCTION(4, 5);
+ (void)logError:(NSString*)domain file:(NSString*)file line:(NSUInteger)line format:(NSString*)format, ... NS_FORMAT_FUNCTION(4, 5);

@end

NS_ASSUME_NONNULL_END