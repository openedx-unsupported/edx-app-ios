//
//  NSString+EDXEncoding.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 11/4/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (EDXEncoding)

- (NSString*)edx_stringByUsingFormEncoding;

@end
