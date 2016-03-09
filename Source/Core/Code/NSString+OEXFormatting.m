//
//  NSString+OEXFormatting.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSString+OEXFormatting.h"

#import "NSBundle+OEXConveniences.h"

/// Determines if parameters has an extra item or is missing something
BOOL OEXFormatStringIsValid(NSString* string, NSDictionary* parameters) {
    __block BOOL isValid = YES;
    __block NSString* current = string;

    // Make sure all the strings are matched
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString* key, id value, BOOL* stop) {
        NSString* token = [NSString stringWithFormat:@"{%@}", key];
        NSString* replacement = [current stringByReplacingOccurrencesOfString:token withString:@""];

        // No replacement happened so we have an unused parameter
        if(replacement.length == current.length) {
            isValid = NO;
            *stop = YES;
        }
        current = replacement;
    }];

    // We've replaced all the strings so we should have no more format arguments at this point
    // Try matching the format regex
    BOOL noReplacement = [current rangeOfString:@"\\{.*\\}" options:NSRegularExpressionSearch].location == NSNotFound;
    isValid = isValid && noReplacement;

    return isValid;
}

@implementation NSString (OEXFormatting)

- (NSString*)oex_uppercaseStringInCurrentLocale {
    return [self uppercaseStringWithLocale:[[NSBundle mainBundle] oex_displayLocale]];
}

- (NSString*)oex_lowercaseStringInCurrentLocale {
    return [self lowercaseStringWithLocale:[[NSBundle mainBundle] oex_displayLocale]];
}

+ (NSString*)oex_stringWithFormat:(NSString*)format parameters:(NSDictionary*)parameters {
    return [format oex_formatWithParameters:parameters];
}

- (NSString*)oex_formatWithParameters:(NSDictionary*)parameters {
    NSAssert(OEXFormatStringIsValid(self, parameters), @"Invalid format string: %@, parameters: %@", self, parameters);
    
    NSMutableString* result = self.mutableCopy;
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString* key, id value, BOOL* stop) {
        NSRange range = NSMakeRange(0, result.length);
        NSString* token = [NSString stringWithFormat:@"{%@}", key];
        [result replaceOccurrencesOfString:token withString:[value description] options:0 range:range];
    }];
    return result;

}

@end
