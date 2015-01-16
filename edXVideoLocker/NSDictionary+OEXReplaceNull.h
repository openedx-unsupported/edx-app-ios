//
//  NSDictionary+OEXReplaceNull.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 04/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (OEXReplaceNull)
- (NSDictionary *) oex_dictionaryByReplacingNullsWithStrings;
@end
