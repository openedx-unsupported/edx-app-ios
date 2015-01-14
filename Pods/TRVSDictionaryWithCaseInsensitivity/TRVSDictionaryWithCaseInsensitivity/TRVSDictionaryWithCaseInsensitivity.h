//
//  TRVSDictionaryWithCaseInsensitivity.h
//  TRVSDictionaryWithCaseInsensitivity
//
//  Created by Travis Jeffery on 7/24/14.
//  Copyright (c) 2014 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for TRVSDictionaryWithCaseInsensitivity.
FOUNDATION_EXPORT double TRVSDictionaryWithCaseInsensitivityVersionNumber;

//! Project version string for TRVSDictionaryWithCaseInsensitivity.
FOUNDATION_EXPORT const unsigned char TRVSDictionaryWithCaseInsensitivityVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <TRVSDictionaryWithCaseInsensitivity/PublicHeader.h>

@interface TRVSDictionaryWithCaseInsensitivity : NSDictionary

- (void)objectAndKeyForKey:(id)key block:(void (^)(id obj, id key))block;

@end

