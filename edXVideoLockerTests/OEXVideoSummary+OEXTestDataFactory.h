//
//  OEXVideoSummary+OEXTestDataFactory.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXVideoSummary.h"

@interface OEXVideoSummary (OEXTestDataFactory)

/// path : OEXVideoPathEntry array
+ (instancetype)freshStubWithName:(NSString*)name path:(NSArray*)path;

@end
