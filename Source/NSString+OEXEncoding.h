//
//  NSString+OEXEncoding.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 11/4/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OEXEncoding)

- (NSString*)oex_stringByUsingFormEncoding;

@end
