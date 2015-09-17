//
//  Logger+OEXObjC.m
//  edX
//
//  Created by Akiva Leffert on 9/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "Logger+OEXObjC.h"

@implementation Logger (OEXObjC)

+ (void)logDebug:(NSString *)domain file:(NSString *)file line:(NSUInteger)line format:(NSString *)format, ... {
    va_list vaArguments;
    va_start(vaArguments, format);
    NSString* message = [[NSString alloc] initWithFormat:format arguments:vaArguments];
    [self logDebug:domain :message file:file line:line];
}

+ (void)logInfo:(NSString *)domain file:(NSString *)file line:(NSUInteger)line format:(NSString *)format, ... {
    va_list vaArguments;
    va_start(vaArguments, format);
    NSString* message = [[NSString alloc] initWithFormat:format arguments:vaArguments];
    [self logInfo:domain :message file:file line:line];
}

+ (void)logError:(NSString *)domain file:(NSString *)file line:(NSUInteger)line format:(NSString *)format, ... {
    va_list vaArguments;
    va_start(vaArguments, format);
    NSString* message = [[NSString alloc] initWithFormat:format arguments:vaArguments];
    [self logError:domain :message file:file line:line];
}

@end
