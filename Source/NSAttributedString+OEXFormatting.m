//
//  NSAttributedString+OEXFormatting.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSAttributedString+OEXFormatting.h"

@implementation NSAttributedString (OEXFormatting)

- (NSAttributedString*)oex_formatWithParameters:(NSDictionary<NSString*, NSAttributedString*>*)parameters {
    NSMutableAttributedString* result = self.mutableCopy;
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSAttributedString* value, BOOL* stop) {
        NSString* token = [NSString stringWithFormat:@"{%@}", key];
        NSError* error = nil;
        NSString* pattern = [NSRegularExpression escapedPatternForString:token];
        NSRegularExpression* expression = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:&error];
        NSAssert(error == nil, @"");
        
        BOOL matchedAll = NO;
        BOOL matchedAny = NO; // used only for dation
        while(!matchedAll) {
            NSRange range = NSMakeRange(0, result.length);
            // Instead of grabbing all the matches at once, we have to repeatedly get one match
            // since the match ranges change once we do a substitution
            NSRange matchRange = [expression rangeOfFirstMatchInString:result.string options:0 range:range];
            if(matchRange.location != NSNotFound) {
                [result replaceCharactersInRange:matchRange withAttributedString:value];
                matchedAny = YES;
            }
            else {
                matchedAll = YES;
            }
        }
        NSAssert(matchedAny, @"Did not find any replacements for %@", value);
    }];
    return result;
}

@end
