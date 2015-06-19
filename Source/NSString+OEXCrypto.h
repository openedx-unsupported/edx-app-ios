//
//  NSString+OEXCrypto.h
//  edX
//
//  Created by Akiva Leffert on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (OEXCrypto)

@property (readonly, nonatomic) NSString* oex_md5;

@end


NS_ASSUME_NONNULL_END
