//
//  NSString+OEXEncoding.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 11/4/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSString (OEXEncoding)

- (NSString*)oex_stringByUsingFormEncoding;

@end

NS_ASSUME_NONNULL_END
