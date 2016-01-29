//
//  NSDictionary+OEXEncoding.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 11/4/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (OEXEncoding)

// All keys and values should be NSStrings
- (NSString*)oex_stringByUsingFormEncoding;

@end

NS_ASSUME_NONNULL_END
