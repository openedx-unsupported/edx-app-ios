//
//  NSJSONSerialization+OEXSafeAccess.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 12/03/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSJSONSerialization (OEXSafeAccess)
+ (id)oex_JSONObjectWithData:(NSData*)data error:(NSError* __autoreleasing*)error;
@end

NS_ASSUME_NONNULL_END
