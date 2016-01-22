//
//  OEXUserDetails+OEXTestDataFactory.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXUserDetails.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXUserDetails (OEXTestDataFactory)

+ (instancetype)freshUser;

@end

NS_ASSUME_NONNULL_END
