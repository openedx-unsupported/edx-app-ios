//
//  NSJSONSerialization+OEXSafeAccess.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 12/03/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSJSONSerialization (OEXSafeAccess)
+(id)oex_jsonObjectWithData:(NSData *)data error:(NSError *__autoreleasing *)error;
@end
