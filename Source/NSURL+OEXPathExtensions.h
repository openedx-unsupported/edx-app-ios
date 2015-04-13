//
//  NSURL+OEXPathExtensions.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 2/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (OEXPathExtensions)

/// Concatentation of host and path, if host or path is nil, then just the one
- (NSString*)oex_hostlessPath;
/// We should deprecate this once we go iOS 8 only and just use queryParams
- (NSDictionary*)oex_queryParameters;

@end
