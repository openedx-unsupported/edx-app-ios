//
//  OEXVideoSummary+OEXTestDataFactory.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/21/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXVideoSummary.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXVideoSummary (OEXTestDataFactory)

/// path : OEXVideoPathEntry array
+ (instancetype)freshStubWithName:(NSString*)name path:(NSArray*)path;

@end

 NS_ASSUME_NONNULL_END
