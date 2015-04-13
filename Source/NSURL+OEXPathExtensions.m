//
//  NSURLOEXPathExtensions.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 2/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSURL+OEXPathExtensions.h"

@implementation NSURL (OEXPathExtensions)

- (NSString*)oex_hostlessPath {
    if(self.host == nil) {
        if(self.path == nil) {
            return nil;
        }
        else {
            return self.path;
        }
    }
    else {
        if(self.path == nil) {
            return self.host;
        }
        else {
            return [NSString stringWithFormat:@"%@/%@", self.host, self.path];
        }
    }
}

- (NSDictionary*)oex_queryParameters {
    NSString* queryString = self.query;
    NSMutableDictionary* queryDictionary = [[NSMutableDictionary alloc] init];
    for(NSString* param in [queryString componentsSeparatedByString : @"&"]) {
        NSArray* keyValuePair = [param componentsSeparatedByString:@"="];
        if([keyValuePair count] < 2) {
            continue;
        }
        [queryDictionary setObject:[keyValuePair objectAtIndex:1] forKey:[keyValuePair objectAtIndex:0]];
    }
    return queryDictionary;
}

@end